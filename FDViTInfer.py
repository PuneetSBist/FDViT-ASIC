
from __future__ import print_function
import json
import torch
from DataLoader import dataset
from torch.utils.data import DataLoader
from torchvision import transforms
#from torch.nn.functional import softmax
from transformers import AutoFeatureExtractor, ViTForImageClassification
from transformers import AutoImageProcessor, AutoModelForImageClassification
import time
import timm
import torch

# Directory paths
image_dir = 'D:\\ImageNet\\ILSVRC2012_img_val'
label_file = 'D:\\ImageNet\\ILSVRC2012_devkit_t12\\ILSVRC2012_devkit_t12\\data\\ILSVRC2012_validation_ground_truth.txt'
properLabelFile = "proper_label.txt"
#properLabelFile = "C:\\Users\\bistp\\Downloads\\CLass\\AdvHardML\\HW1_b\\ViT\\model\\proper_label.txt"

# choose if you want to use GPU or CPU here
def enable_cuda(no_cuda):
    USING_PUNEET_GPU = 2
    USING_COLLAB_GPU = 3
    gpu_index = USING_COLLAB_GPU
    if "NVIDIA GeForce RTX 4050 Laptop GPU" == torch.cuda.get_device_name(0):
        gpu_index = USING_PUNEET_GPU
    print(f'GPU to be used: {"Collab Nvidia T4" if gpu_index == 1 else "Puneet RTX 4050"}')
    # Derived parameters
    use_cuda = not no_cuda and torch.cuda.is_available()
    device = torch.device("cuda" if use_cuda else "cpu")
    print("should enbale GPU? ", use_cuda)
    return device


def get_model(modelName):
    model = None
    if modelName == "FDViT":
        model = AutoModelForImageClassification.from_pretrained("amd/FDViT_ti", trust_remote_code=True)
        model.eval()
        """
        transform = transforms.Compose([
            transforms.Resize((224, 224)),  # Resize images to 224x224
            transforms.ToTensor()  # Convert image to tensor
        ])
        """
        transform = transforms.Compose([
            transforms.Resize((224, 224)),  # Resize images to 224x224
            transforms.ToTensor(),  # Convert image to tensor
            transforms.Normalize(mean=[0.485, 0.456, 0.406], std=[0.229, 0.224, 0.225])  # Normalize (ImageNet stats)
        ])
    elif modelName == "FDViT-B":
        model = AutoModelForImageClassification.from_pretrained("amd/FDViT_b", trust_remote_code=True)
        model.eval()
        transform = transforms.Compose([
            transforms.Resize((224, 224)),  # Resize images to 224x224
            transforms.ToTensor(),  # Convert image to tensor
            transforms.Normalize(mean=[0.485, 0.456, 0.406], std=[0.229, 0.224, 0.225])  # Normalize (ImageNet stats)
        ])
    elif modelName == "volo_d4_448":
        model = timm.create_model('volo_d4_448.sail_in1k', pretrained=True)
        model = model.eval()
        # get model specific transforms (normalization, resize)
        data_config = timm.data.resolve_model_data_config(model)
        transform = timm.data.create_transform(**data_config, is_training=False)
    elif modelName == "Deit":
        model = ViTForImageClassification.from_pretrained('facebook/deit-tiny-patch16-224')
        transform = AutoFeatureExtractor.from_pretrained('facebook/deit-tiny-patch16-224')

    elif modelName == "Pit":
        model = timm.create_model('pit_ti_224.in1k', pretrained=True)
        model = model.eval()
        data_config = timm.data.resolve_model_data_config(model)
        transform = timm.data.create_transform(**data_config, is_training=False)

    elif modelName == "Resnet":
        transform = AutoImageProcessor.from_pretrained("microsoft/resnet-18")
        model = AutoModelForImageClassification.from_pretrained("microsoft/resnet-18")

    return model,transform


def get_dataloader(modelName, transform, num_images_needed=128):
    dataloader = None
    if modelName == "Deit" or modelName == "Resnet":
        mydata = dataset(image_dir, properLabelFile, transDeit=transform, count=num_images_needed)
        dataloader = mydata.getDataLoader()
    else:
    #elif modelName == "FDViT":
        mydata = dataset(image_dir, properLabelFile, transform=transform, count=num_images_needed)
        dataloader = mydata.getDataLoader()
    """
    elif modelName == "Pit":
        mydata = dataset(image_dir, label_file, transPit=transform, count=num_images_needed)
        dataloader = mydata.getDataLoader()
    """
    return dataloader


def delete_old_model(model, dataloader):
    model.cpu()
    # Delete the model and input data
    del model
    del dataloader
    # Clear CUDA cache
    torch.cuda.empty_cache()
    return


def validate(modelName, device, model, dataloader, checkLatency=False, checkAccuracy=False, predictStat=False, isDummy=False):
    result_list = []
    if predictStat:
        for i in range(1000):
            result_list.append({})

    total_image = 0
    accurate = 0
    if checkLatency:
        start_time = time.perf_counter()
    for iter,(image,label) in enumerate(dataloader):
        predicted_class_idx = -1
        """
        print(image.shape, label)
        print(image.min(), image.max())
        min_per_channel = image.min(dim=2)[0].min(dim=2)[0]  # Reduce height (dim=2) and width (dim=3)
        max_per_channel = image.max(dim=2)[0].max(dim=2)[0]
        print("Min values per channel:", min_per_channel)
        print("Max values per channel:", max_per_channel)
        """
        image = image.to(device)
        if isDummy == False:
            output = model(image)

            if modelName == "Pit" or modelName == "volo_d4_448":
                #top_probabilities, top_class_indices = torch.topk(output.softmax(dim=1) * 100, k=1)
                predicted_class_idx = torch.argmax(output, dim=1).item()
            else:
                logits = output.logits
                #probabilities = softmax(logits, dim=-1)
                #predicted_class = torch.argmax(probabilities, dim=-1).item()
                #print(f"Predicted class index: {predicted_class}")
                predicted_class_idx = logits.argmax(-1).item()

        #print("Predicted class:", model.config.id2label[predicted_class_idx])
        if (iter+1) % 500 == 0:
            print(f"{modelName} processed {iter+1} items")
        #print(label, " Vs ", predicted_class_idx)
        if checkAccuracy:
            if predicted_class_idx == label:
                accurate += 1
            total_image += 1

        if predictStat:
            result_list[label-1][predicted_class_idx] = result_list[label-1].get(predicted_class_idx, 0) + 1

    if checkLatency:
        end_time = time.perf_counter()
        print(f"{modelName} Execution time: {end_time - start_time} seconds")
    if checkAccuracy:
        print(f"{modelName} Accuracy : {accurate/total_image} ")
    return result_list


def save_dict_of_list(result, filename):
    label = 1
    with open(filename, 'w') as file:
        for dictData in result:
            file.write(str(label)+":")
            json.dump(dictData, file)
            file.write('\n')
            label += 1


def run_volo_d4_448_Full(enable_gpu=False, file_prefix=""):
    device = enable_cuda(no_cuda=not enable_gpu)

    model,transform = get_model("volo_d4_448")
    model.to(device)
    data_loader = get_dataloader("FDViT", transform, -1)
    result = validate("volo_d4_448", device, model, data_loader, checkLatency=True, checkAccuracy=True, predictStat=True)
    save_dict_of_list(result, file_prefix+ "volo_d4_448.txt")
    delete_old_model(model, data_loader)



def run_FDVit_Full(enable_gpu=False, file_prefix=""):
    device = enable_cuda(no_cuda=not enable_gpu)

    fdvit_model,transform = get_model("FDViT")
    fdvit_model.to(device)
    fdvit_loader = get_dataloader("FDViT", transform, -1)
    result = validate("FDViT", device, fdvit_model, fdvit_loader, checkLatency=True, checkAccuracy=True, predictStat=True)
    save_dict_of_list(result, file_prefix+ "FDViT_label.txt")
    delete_old_model(fdvit_model, fdvit_loader)
    """
    fdvit_b_model,transform_b = get_model("FDViT-B")
    fdvit_b_model.to(device)
    fdvit_loader = get_dataloader("FDViT", transform_b, -1)
    result = validate("FDViT-B", device, fdvit_b_model, fdvit_loader, checkLatency=True, checkAccuracy=True, predictStat=True)
    save_dict_of_list(result, file_prefix+ "FDViT_B_label.txt")
    delete_old_model(fdvit_b_model, fdvit_loader)
    """


def run_model_latency(enable_gpu=False, image_set_count=1000, file_prefix=""):
    device = enable_cuda(no_cuda=not enable_gpu)

    fdvit_model,transform = get_model("FDViT")
    fdvit_model.to(device)
    fdvit_loader = get_dataloader("FDViT", transform, image_set_count)
    result = validate("FDViT", device, fdvit_model, fdvit_loader, checkLatency=True, checkAccuracy=True, predictStat=False)
    #save_dict_of_list(result, file_prefix+ "FDViT_label.txt")
    delete_old_model(fdvit_model, fdvit_loader)

    deit_model,transform2 = get_model("Deit")
    deit_model.to(device)
    deit_loader = get_dataloader("Deit", transform2, num_images_needed=image_set_count)
    result = validate("Deit", device, deit_model, deit_loader, checkLatency=True, checkAccuracy=True, predictStat=False)
    #save_dict_of_list(result, file_prefix+ "Deit_label.txt")
    delete_old_model(deit_model, deit_loader)

    pit_model,transform3 = get_model("Pit")
    pit_model.to(device)
    pit_loader = get_dataloader("Pit", transform3, image_set_count)
    result = validate("Pit", device, pit_model, pit_loader, checkLatency=True, checkAccuracy=True, predictStat=False)
    #save_dict_of_list(result, file_prefix+ "Pit_label.txt")
    delete_old_model(pit_model, pit_loader)

    resnet_model,transform4 = get_model("Resnet")
    resnet_model.to(device)
    resnet_loader = get_dataloader("Resnet", transform4, num_images_needed=image_set_count)
    result = validate("Resnet", device, resnet_model, resnet_loader, checkLatency=True, checkAccuracy=True, predictStat=False)
    #save_dict_of_list(result, file_prefix+ "Resnet_label.txt")
    delete_old_model(resnet_model, resnet_loader)

    fdvit_model,transform = get_model("FDViT")
    fdvit_loader = get_dataloader("FDViT", transform, image_set_count)
    result = validate("Dummy", device, None, fdvit_loader, checkLatency=True, checkAccuracy=True, predictStat=False, isDummy=True)
    delete_old_model(fdvit_model, fdvit_loader)
