# COP OpenCL

Experimenting with copernicus, the long-awaited GPU texture/shader context of Houdini.
The main purpose of this repo is to show various approaches for learning purposes. 

Do not hesitate to reach or PR nodes that others could learn from.

## Nodes

### Weave

This is an almost 1/1 copy of the OSL version for 3DSMax by Zap Anderson ([osl source code](https://github.com/ADN-DevTech/3dsMax-OSL-Shaders/blob/master/3ds%20Max%20Shipping%20Shaders/Weave.osl)),
it outputs color, bump, ID and opacity

<img src="https://github.com/user-attachments/assets/6f92cc24-b59d-4c5e-a635-8fcf73a11cbd" width=512/>

### Split Gaussian Blur

This is very slow for now compared to the built-in gaussian blur.  
The main idea is to use a `float4` as `sigma`, allowing to blur each channels (supports RGBA) independently.
For convenience, it also has a global `float` sigma multiplier.

<img src="https://github.com/user-attachments/assets/13139f4d-d28d-49c5-8d72-9b53faa39bc9" width=512/>

### Glow 

Naive glow, like the edge detection this should yield better results if done in multiple kernels (for instance extract highlights, blur,pasteback).
Keeping it for reference too.

<img src="https://github.com/user-attachments/assets/f93274e8-20d7-4da4-8039-29c22080a7c2" width=1024/>

### Pixelize


<img src="https://github.com/user-attachments/assets/8a2ff8b6-09e4-4bbd-81e0-1951fa60e5b2" width=1024/>
