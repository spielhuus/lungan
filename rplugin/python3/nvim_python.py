import pynvim
import openvino_genai
import threading
import json
from queue import Queue
from time import sleep


class NvimCallbackStreamer:
    def __init__(self, nvim, callback_func, dispatcher_id):
        self.nvim = nvim
        self.callback_func = callback_func
        self.dispatcher_id = dispatcher_id

    # This __call__ method is what the OpenVINO pipeline will invoke for each token
    def __call__(self, token_text: str) -> bool:
        try:
            payload = {
                "dispatcher": self.dispatcher_id,
                "done": False,
                "message": {
                    "role": "assistant",
                    "content": token_text
                }
            }
            # Use async_call to safely send the token to Neovim's main thread
            self.nvim.async_call(self.callback_func, json.dumps(payload))
        except Exception as e:
            # If something goes wrong during the callback, report it
            self.nvim.async_call(self.nvim.err_writeln, f"Error in streamer callback: {e}")
        
        # Return True to continue generation. Returning False would stop it.
        return False


class NvimStreamer:
    """
    This class is now correct. It will be called from the generation loop.
    """
    def __init__(self, nvim, buf, dispatcher_id):
        self.nvim = nvim
        self.buf = buf
        self.id = dispatcher_id 

    def __call__(self, token_text: str) -> bool:
        self.nvim.async_call(self._process_token_in_nvim, token_text)
        return False

    # def _process_token_in_nvim(self, token: str):
    #     """
    #     This single function handles ALL Neovim API calls for a given token.
    #     It is always executed safely on the main thread.
    #     """
    #     try:
    #         lines = token.split('\n')
    #         payload = {
    #             "dispatcher": self.id,
    #             "done": False,
    #             "message": {
    #                 "role": "assistant",
    #                 "content": token
    #             }
    #         }
    #         # json_payload_string = json.dumps(payload)
    #         # lua_safe_string_arg = json.dumps(json_payload_string)
    #
    #         self.lua_dispatcher.dispatch(json.dumps(payload))
    #
    #         # self.nvim.async_call(self.nvim.call, 'luaeval', 'require("lungan.nvim").options.providers.Openvino.dispatch(_A)', json.dumps(payload))
    #
    #
    #         # lua_command = f'require("lungan.nvim").options.providers.Openvino:dispatch({lua_safe_string_arg})'
    #         # self.nvim.exec_lua(lua_command)
    #
    #     except pynvim.NvimError as e:
    #         self.nvim.err_writeln(f"Nvim API Error during token processing: {e}")
    #     except Exception as e:
    #         self.nvim.err_writeln(f"Generic Error during token processing: {e}")

    # def _process_token_in_nvim(self, token: str):
    #     try:
    #         lines = token.split('\n')
    #           #"model": "llama3.2",
    #           #"created_at": "2023-08-04T08:52:19.385406455-07:00",
    #         result = f'{{ "dispatcher": {self.id}, "message": {{ "role": "assistant", "content": "{token}" }}, "done": false }}'
    #         # json_result = f'{{ "message": {{ "content": "{token}" }} }}'
    #         safe_token_str = json.dumps(result)
    #         lua_command = f'require("lungan.nvim").options.providers.Openvino:dispatch({safe_token_str})'
    #         self.nvim.exec_lua(lua_command)
    #
    #     except pynvim.NvimError as e:
    #         self.nvim.err_writeln(f"Nvim API Error during token processing: {e}")
    #     except Exception as e:
    #         self.nvim.err_writeln(f"Generic Error during token processing: {e}")

    # def end(self):
    #     # self.nvim.async_call(self.buf.append, "n--- Streaming Finished ---")
    #     pass


@pynvim.plugin
class OpenvinoPlugin:
    def __init__(self, nvim):
        self.nvim = nvim

    @pynvim.function("LongBlock")
    def long_block(self, args):
        while(true):
            sleep(5)
            self.nvim.command('echo "done with blocking stuff"')

    @pynvim.function('OpenvinoChat', sync=False)
    def openvino_chat(self, args):
        try:
            dispatcher_id = args[1] 
            lua_vino_func = self.nvim.lua.vino
            
            provider = args[2]['provider']
    
            model_path = f'{provider["path"]}{provider["model"]}'
            self.nvim.async_call(self.nvim.lua.debug_callback, f'Openvino Path: {model_path}')

            request = []
            request.append(
                {"role": "system", "content": args[2]['system_prompt']}
            )

            for item in args[2]['messages']:
                request.append(
                    {"role": item['role'], "content": item['content']}
                )

            self.nvim.async_call(self.nvim.lua.debug_callback, f'Openvino request: {json.dumps(request)}')

            config = openvino_genai.GenerationConfig()
            config.max_new_tokens = 10000

            worker_thread = threading.Thread(
                target=self.do_long_work, 
                args=(lua_vino_func, request, config, model_path, dispatcher_id) # Pass model_path
            )
            worker_thread.start()

        except Exception as e:
            self.nvim.err_writeln(f"Error in OpenvinoChat setup: {e}")
            return

        self.nvim.out_write("Python: Background task started. Neovim UI is not blocked.")

    def do_long_work(self, vino_callback, prompt, config, model_path, dispatcher_id):
        try:
            # Initialize the pipeline inside the thread
            tokenizer = openvino_genai.Tokenizer(model_path)
            pipe = openvino_genai.LLMPipeline(model_path, tokenizer=tokenizer, device="GPU")

            model_inputs = tokenizer.apply_chat_template(prompt, add_generation_prompt=True)
            streamer = NvimCallbackStreamer(self.nvim, vino_callback, dispatcher_id)
            answer = pipe.generate(model_inputs, generation_config=config, streamer=streamer)

            done_payload = {
                "dispatcher": dispatcher_id,
                "done": True,
                "message": { "role": "assistant", "content": "" }
            }
            self.nvim.async_call(vino_callback, json.dumps(done_payload))

        except BaseException as e:
            message = f'{e}'
            error_message = {
                "dispatcher": dispatcher_id,
                "done": True,
                "error": {"message": message}
            }
            self.nvim.async_call(vino_callback, json.dumps(error_message))
            # self.nvim.async_call(vino_callback, "Error")
