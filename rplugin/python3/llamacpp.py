import pynvim
import openvino_genai
import threading
import json
from queue import Queue

@pynvim.plugin
class LLamacpp:
    def __init__(self, nvim):
        self.nvim = nvim

    @pynvim.function('LlamaCppChat', sync=False)
    def openvino_chat(self, args):
        model_path = "~/.models"
        buffer_id = args[0]
        dispatcher_id = args[1]
        prompt_table = args[2]
        
        try:
            buf = self.nvim.buffers[buffer_id]
        except (IndexError, pynvim.NvimError):
            self.nvim.err_writeln(f"Invalid buffer ID: {buffer_id}")
            return
        
        # Create a thread-safe queue to communicate between threads
        token_queue = Queue()

        # Start the background thread (The Producer)
        producer_thread = threading.Thread(
            target=self.generation_task,
            args=(prompt_table, token_queue, model_path) # Pass the queue to the thread
        )
        producer_thread.start()

        # Start the foreground task (The Consumer)
        self.process_queue(buf, dispatcher_id, token_queue)

    def process_queue(self, buf, dispatcher_id, token_queue):
        """
        The Consumer. Runs on the main thread.
        Checks the queue for new tokens and processes them.
        """
        try:
            # Get a token from the queue without blocking
            # The `None` object is a special signal that the stream is finished.
            token = token_queue.get_nowait()

            if token is None:
                # End of stream. Do any final cleanup.
                buf.append(["", "--- Streaming Finished (Queue) ---"])
                return # Stop the processing loop

            # If we got a token, process it (call Lua, etc.)
            self._send_token_to_lua(dispatcher_id, token)

        except Exception:
            # The queue is empty, which is normal. We don't need to do anything.
            pass

        # IMPORTANT: Re-schedule this function to run again very soon.
        # This creates a timer-like loop on the main thread that constantly
        # checks the queue for new items.
        self.nvim.async_call(self.process_queue, buf, dispatcher_id, token_queue)

    def _send_token_to_lua(self, dispatcher_id, token):
        """
        This is the logic that was in NvimStreamer. It's now just a helper method.
        It is always called from the main thread via process_queue.
        """
        try:
            payload = {
                "dispatcher": dispatcher_id,
                "done": False,
                "message": { "role": "assistant", "content": token }
            }
            json_payload_string = json.dumps(payload)
            lua_safe_string_arg = json.dumps(json_payload_string)
            lua_command = f'require("lungan.nvim").options.providers.Openvino:dispatch({lua_safe_string_arg})'
            self.nvim.exec_lua(lua_command)
        except Exception as e:
            self.nvim.err_writeln(f"Error in _send_token_to_lua: {e}")

    def generation_task(self, prompt_table, token_queue, model_path):
        """
        The Producer. Runs in a background thread.
        Its ONLY job is to generate tokens and put them in the queue.
        It NEVER touches the Neovim API.
        """
        try:
            request_text = prompt_table['messages'][0]['content']
            pipe = openvino_genai.LLMPipeline(model_path, "GPU", CACHE_DIR="cache")
            config = openvino_genai.GenerationConfig(max_new_tokens=1000)

            for token in pipe(request_text, generation_config=config):
                # Put the generated token into the queue.
                token_queue.put(token)
        
        except Exception as e:
            # If an error happens, put the error message in the queue
            error_payload = { "error": str(e) } # You can design your error format
            token_queue.put(json.dumps(error_payload))
        
        finally:
            # CRITICAL: When the loop is done, put a special `None` value
            # into the queue. This is the signal for the consumer to stop.
            token_queue.put(None)
