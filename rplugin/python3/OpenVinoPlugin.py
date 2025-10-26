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
        self.request_stop = False

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
            self.nvim.async_call(self.nvim.lua.debug_callback, f'Streamer request_stop = {self.request_stop}')
            self.nvim.async_call(self.callback_func, json.dumps(payload))
        except Exception as e:
            self.nvim.async_call(self.nvim.err_writeln, f"Error in streamer callback: {e}")
        
        return self.request_stop

@pynvim.plugin
class OpenvinoPlugin:
    def __init__(self, nvim):
        self.nvim = nvim
        self.pipe = {}
        self.streamer = None

    @pynvim.function('OpenvinoStop', sync=False)
    def openvino_stop(self, args):
        if self.streamer:
            self.streamer.request_stop = True


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
            # TODO: set the rest of the parameters

            worker_thread = threading.Thread(
                target=self.do_long_work, 
                args=(lua_vino_func, request, config, model_path, dispatcher_id) # Pass model_path
            )
            worker_thread.start()

        except Exception as e:
            message = f'{e}'
            error_message = {
                "dispatcher": dispatcher_id,
                "done": True,
                "error": {"message": message}
            }
            self.nvim.async_call(vino_callback, json.dumps(error_message))
            return

        self.nvim.out_write("Python: Background task started. Neovim UI is not blocked.")

    def do_long_work(self, vino_callback, prompt, config, model_path, dispatcher_id):
        try:
            tokenizer = openvino_genai.Tokenizer(model_path)
            if not model_path in self.pipe:
                self.nvim.async_call(self.nvim.lua.debug_callback, f'Load Openvino Model: {model_path}')
                self.pipe[model_path] = openvino_genai.LLMPipeline(model_path, tokenizer=tokenizer, device="GPU")

            model_inputs = tokenizer.apply_chat_template(prompt, add_generation_prompt=True)
            self.streamer = NvimCallbackStreamer(self.nvim, vino_callback, dispatcher_id)
            answer = self.pipe[model_path].generate(model_inputs, generation_config=config, streamer=self.streamer)

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
