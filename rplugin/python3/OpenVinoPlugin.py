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
            if 'echo' in args[2]['options']:
                config.echo = args[2]['options']['echo']
            if 'eos_token_id' in args[2]['options']:
                config.eos_token_id = args[2]['options']['eos_token_id']
            if 'frequency_penalty' in args[2]['options']:
                config.frequency_penalty = args[2]['options']['frequency_penalty']
            if 'ignore_eos' in args[2]['options']:
                config.ignore_eos = args[2]['options']['ignore_eos']
            if 'include_stop_str_in_output' in args[2]['options']:
                config.include_stop_str_in_output = args[2]['options']['include_stop_str_in_output']
            if 'length_penalty' in args[2]['options']:
                config.length_penalty = args[2]['options']['length_penalty']
            if 'logprobs' in args[2]['options']:
                config.logprobs = args[2]['options']['logprobs']
            if 'max_length' in args[2]['options']:
                config.max_length = args[2]['options']['max_length']
            if 'max_new_tokens' in args[2]['options']:
                config.max_new_tokens = args[2]['options']['max_new_tokens']
            if 'max_ngram_size' in args[2]['options']:
                config.max_ngram_size = args[2]['options']['max_ngram_size']
            if 'min_new_tokens' in args[2]['options']:
                config.min_new_tokens = args[2]['options']['min_new_tokens']
            if 'no_repeat_ngram_size' in args[2]['options']:
                config.no_repeat_ngram_size = args[2]['options']['no_repeat_ngram_size']
            if 'num_assistant_tokens' in args[2]['options']:
                config.num_assistant_tokens = args[2]['options']['num_assistant_tokens']
            if 'num_beam_groups' in args[2]['options']:
                config.num_beam_groups = args[2]['options']['num_beam_groups']
            if 'num_beams' in args[2]['options']:
                config.num_beams = args[2]['options']['num_beams']
            if 'num_return_sequences' in args[2]['options']:
                config.num_return_sequences = args[2]['options']['num_return_sequences']
            if 'presence_penalty' in args[2]['options']:
                config.presence_penalty = args[2]['options']['presence_penalty']
            if 'repetition_penalty' in args[2]['options']:
                config.repetition_penalty = args[2]['options']['repetition_penalty']
            if 'rng_seed' in args[2]['options']:
                config.rng_seed = args[2]['options']['rng_seed']
            if 'stop_criteria' in args[2]['options']:
                config.stop_criteria = args[2]['options']['stop_criteria']
            if 'stop_strings' in args[2]['options']:
                config.stop_strings = args[2]['options']['stop_strings']
            if 'stop_token_ids' in args[2]['options']:
                config.stop_token_ids = args[2]['options']['stop_token_ids']
            if 'structured_output_config' in args[2]['options']:
                config.structured_output_config = args[2]['options']['structured_output_config']
            if 'temperature' in args[2]['options']:
                config.temperature = args[2]['options']['temperature']
            if 'top_k' in args[2]['options']:
                config.top_k = args[2]['options']['top_k']
            if 'top_p' in args[2]['options']:
                config.top_p = args[2]['options']['top_p']

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
