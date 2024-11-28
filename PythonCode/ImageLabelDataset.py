import torch
from torch.utils.data import Dataset, DataLoader
from PIL import Image
import os

def load_labels(label_file_path, count):
    with open(label_file_path, 'r') as f:
        labels = [int(line.strip()) for line in f.readlines()]
    labels = labels[:count] if count != -1 else labels
    return labels

class ImageLabelDataset(Dataset):
    def __init__(self, image_dir, label_file, transform=None, count=-1, transDeit=None):
        """
        Args:
            image_dir (str): Path to the directory with images.
            label_file (str): Path to the file containing labels.
            transform (callable, optional): Optional transform to be applied on an image.
        """
        self.image_dir = image_dir
        self.labels = load_labels(label_file, count)  # Load labels from file
        self.image_filenames = sorted(os.listdir(image_dir))[:count] if count != -1 else sorted(os.listdir(image_dir))
        self.transform = transform
        self.transDeit = transDeit

    def __len__(self):
        return len(self.image_filenames)  # Number of images

    def __getitem__(self, idx):
        img_name = self.image_filenames[idx]
        img_path = os.path.join(self.image_dir, img_name)

        # Open image file
        image = Image.open(img_path).convert('RGB')  # Make sure it's in RGB format

        # Get label based on line number in the label file
        label = self.labels[idx]

        # Apply transformations if any
        if self.transform:
            image = self.transform(image)
        elif self.transDeit:
            image = self.transDeit(images=image, return_tensors="pt")
            image = image['pixel_values']
            image = image.squeeze(0)

        return image, torch.tensor(label)
