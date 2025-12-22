# TensorFlow Lite Model

## MobileNet v2 Model

This directory should contain the MobileNet v2 TensorFlow Lite model for image classification.

### Download Instructions

**Option 1: Using TensorFlow Hub (Recommended)**
1. Visit: https://tfhub.dev/tensorflow/lite-model/mobilenet_v2_1.0_224/2/default/1
2. Click "Download" or use the direct link
3. The file will be named something like `mobilenet_v2_1.0_224.tflite`
4. Rename it to `mobilenet_v2.tflite` and place in this directory

**Option 2: Using TensorFlow Lite Model Maker**
1. Install TensorFlow Lite Model Maker (Python):
   ```bash
   pip install tflite-model-maker
   ```
2. Convert MobileNet v2 to TFLite:
   ```python
   from tflite_model_maker import image_classifier
   # Follow TensorFlow Lite Model Maker documentation
   ```

**Option 3: Manual Download from GitHub**
1. Visit: https://github.com/tensorflow/models
2. Search for "mobilenet" in the repository
3. Look for pre-converted `.tflite` files
4. Download a MobileNet v2 model with 224x224 input size

**Option 4: Use Pre-trained Models Repository**
- **Kaggle**: Search for "MobileNet v2 TensorFlow Lite"
- **Hugging Face**: https://huggingface.co/models?search=mobilenet
- **Model Zoo**: Various ML model repositories

**After Download:**
1. Rename the downloaded file to `mobilenet_v2.tflite`
2. Place it in this directory: `assets/models/mobilenet_v2.tflite`
3. Verify the file is approximately **3-14 MB** in size
4. The app will automatically detect and use the model

### Model Information

- **Model**: MobileNet v2
- **Input Size**: 224x224 pixels
- **Input Format**: RGB normalized to [-1, 1]
- **Output**: 1000 ImageNet classes
- **Size**: ~3-14 MB (depending on quantization)

### Fallback Behavior

If the model file is not present, the app will:
- Use heuristic-based tag generation
- Generate tags based on container type (box, bag, drawer)
- Add common storage-related keywords

This ensures the app works even without the ML model, though with less accurate tag generation.

