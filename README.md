# TorchJS

[![npm version](https://badge.fury.io/js/%40techainer1t%2Ftorch-js.svg)](https://badge.fury.io/js/%40techainer1t%2Ftorch-js) [![CI](https://github.com/Techainer/torch-js/actions/workflows/ci.yml/badge.svg)](https://github.com/Techainer/torch-js/actions/workflows/ci.yml) [![publish-prebuild](https://github.com/Techainer/torch-js/actions/workflows/publish-prebuild.yml/badge.svg)](https://github.com/Techainer/torch-js/actions/workflows/publish-prebuild.yml)

TorchJS is a JS binding for PyTorch. Its primary objective is to allow running [TorchScript](https://pytorch.org/docs/master/jit.html) inside Node.js program. Complete binding of libtorch is possible but is out-of-scope at the moment.

This fork is maintained by [Techainer](https://techainer.com)
## Changes after fork

- Add support for `List` (Javascript `Array`), `Dict` (Javascript `Object`), `String`, `float` (Javascript `number`) as inputs and outputs.

- Add CUDA support.

- Add ops from torchvision.

- Add async support for `forward` function.

- Add async support for `call_scripted_function(function_name, **inputs)` to call any method of the scripted module.

- Provide prebuild binary for cross NVIDIA GPU from Pascal to Ampere

- Fixed some weird conversion arround `List[Tensor]` input.

- Updated `libtorch` to `1.8.1` and `torchvision` to `0.9.1`

## Install

To install the forked version, you can install it from npm:

```bash
yarn add torch-js@npm:@techainer1t/torch-js
```

## Example

In `tests/resources/torch_module.py`, you will find the defination of our test module and the code to generate the trace file.

```python
class TestModule(torch.nn.Module):
    def __init__(self):
        super(TestModule, self).__init__()

    def forward(self, input1, input2):
        return input1 + input2
```

Once you have the trace file, it may be loaded into NodeJS like this

```javascript
const torch = require("torch-js");
const modelPath = `test_model.pt`;
const model = new torch.ScriptModule(testModelPath);
const inputA = torch.rand([1, 5]);
const inputB = torch.rand([1, 5]);
const res = await model.forward(inputA, inputB);
```

More examples regarding tensor creation, ScriptModule operations, and loading models can be found in our [examples](./examples) folder.
