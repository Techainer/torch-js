# Sample ScriptModule Usage

## forward

The script_module may be used to load up any model in TorchScript, and perform operations on it

```js
const torch = require("torch-js");
const modelPath = `test_model.pt`;
const model = new torch.ScriptModule(testModelPath);
const inputA = torch.rand([1, 5]);
const inputB = torch.rand([1, 5]);
const res = await model.forward(inputA, inputB);
```

## call_scripted_function

The script_module can and perform any operations on it, with the syntax: `call_scripted_function(function_name, **inputs)`

```js
const torch = require("torch-js");
const modelPath = `test_model_2.pt`;
const model = new torch.ScriptModule(testModelPath);
const inputA = torch.rand([1, 5]);
const inputB = torch.rand([1, 5]);
const res = await model.call_scripted_function("forward_batch", [inputA, inputB]);
```
