import pynvim
import openvino_genai
import threading
import json
from queue import Queue
from time import sleep

@pynvim.plugin
class TestPlugin:
    def __init__(self, nvim):
        self.nvim = nvim

    @pynvim.function("LongBlock", sync=False)
    def long_block(self, args):

        # 1. Resolve the Lua function proxy ONCE in the main thread.
        try:
            # This will raise an error immediately if _G.vino doesn't exist.
            lua_vino_func = self.nvim.lua.vino

            # model_path = os.environ.get("MODEL_PATH", "Mistral-7B-Instruct-v0.3-int8-ov")
            model_path = "/home/etienne/opt/chat/models/Qwen2.5-Coder-1.5B-Instruct-int4-ov" #os.environ.get("MODEL_PATH", "Mistral-7B-Instruct-v0.3-int8-ov")
            #model_path = "/home/etienne/.cache/huggingface/hub/models--OpenVINO--Qwen3-8B-int4-ov/snapshots/4b9e271cdb8a2da17bdd658ca5329ebb8651f3e3"
            # model_path = "/home/etienne/.models"
            pipe = openvino_genai.LLMPipeline(model_path, "GPU", CACHE_DIR="cache")
            # self.nvim.async_call(self.nvim.lua.vino, "LoadedModel")

            config = openvino_genai.GenerationConfig()
            config.max_new_tokens = 1000
            # config.apply_chat_template = False
            prompt = "what is a rust trait"

        except Exception as e:
            self.nvim.err_writeln(f"Error: Could not find the Lua function '_G.vino'. Make sure it is defined. Details: {e}")
            # Stop here; don't even start the thread.
            return

        worker_thread = threading.Thread(target=self.do_long_work, args=(lua_vino_func,prompt,config,pipe,))
        worker_thread.start()
        self.nvim.out_write("Python: Background task started. Neovim UI is not blocked.")


    def do_long_work(self, vino_callback, prompt, config, pipe):

        def streamer_callback(token: str) -> bool:
            # current_line = self.nvim.call('line', '.')
            # self.nvim.async_call(vino_callback, json.dumps({ "token": str }))
            self.nvim.async_call(vino_callback, token)
            return False

        try:
            # for i in range(5):
                # message = f"Update from background thread: {i+1}"
                # This is SAFE. It schedules the Lua function to run on the main loop.
           pipe.generate(prompt, config, streamer=streamer_callback)
                # # self.nvim.async_call(vino_callback, f"OpenvinoEnter {i}")
                # sleep(1) # Simulate doing hard work

            # Signal completion
            # self.nvim.async_call(self.my_lua_callback, "--- Task Finished ---")

        except Exception as e:
            # It's also safe to report errors asynchronously
            self.nvim.async_call(self.nvim.err_writeln, f"Error in background thread: {e}")

        # self.nvim.async_call(self.nvim.lua.vino, "OpenvinoEnter")
        # self.nvim.async_call(self.nvim.lua.vino, "OpenvinoEnter")
        # # buf = self.nvim.buffers[args[0]] #TODO remove
        #
        # # model_path = os.environ.get("MODEL_PATH", "Mistral-7B-Instruct-v0.3-int8-ov")
        # # model_path = "/home/etienne/opt/chat/models/Qwen2.5-Coder-1.5B-Instruct-int4-ov" #os.environ.get("MODEL_PATH", "Mistral-7B-Instruct-v0.3-int8-ov")
        # model_path = "/home/etienne/.cache/huggingface/hub/models--OpenVINO--Qwen3-8B-int4-ov/snapshots/4b9e271cdb8a2da17bdd658ca5329ebb8651f3e3"
        # # model_path = "/home/etienne/.models"
        # pipe = openvino_genai.LLMPipeline(model_path, "GPU", CACHE_DIR="cache")
        # self.nvim.async_call(self.nvim.lua.vino, "LoadedModel")
        #
        # config = openvino_genai.GenerationConfig()
        # config.max_new_tokens = 1000
        # config.apply_chat_template = False
        #
        # pipe.start_chat()
        # prompt = "ahoi sailor"
        # # template = f'<|user|>\n{prompt}</s>\n<|assistant|>'
        #
        # self.nvim.async_call(self.nvim.lua.vino, "DefineFunction")
        # # FIX #1: Correct the streamer lambda to actually use the 'token' variable.
        # # This simple version just prints the token to the Neovim message area.
        # # It's good for debugging.
        # def streamer_callback(token: str) -> bool:
        #
        #     # For debugging, you can write to the error buffer.
        #     # self.nvim.err_writeln(token)
        #
        #     # To append to the buffer, you need to handle newlines correctly.
        #     # This is a more complex example if you want to write to the buffer directly.
        #     current_line = self.nvim.call('line', '.')
        #     # last_col = self.nvim.call('col', [current_line, '$']) - 1
        #     self.nvim.async_call(self.nvim.lua.vino, current_line)
        #     # buf.append(token.split('\n'), index=current_line - 1)
        #
        #     # Return False to continue generation
        #     return openvino_genai.StreamingStatus.RUNNING
        #
        #
        # self.nvim.async_call(self.nvim.lua.vino, "OpenvinoStart")
        # buf.append("OpenvinoStart")
        # pipe.generate(prompt, config, streamer=streamer_callback)
        # pipe.finish_chat()
        # buf.append("OpenvinoEnd")

