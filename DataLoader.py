from ImageLabelDataset import ImageLabelDataset
from torch.utils.data import DataLoader

class dataset:
    def __init__(self, image_dir, label_file, transform=None, count=-1, transDeit=None):
        dataset = ImageLabelDataset(image_dir=image_dir, label_file=label_file, transform=transform, count=count, transDeit=transDeit)
        self.dataloader = DataLoader(dataset, batch_size=1, shuffle=True)

    def getDataLoader(self):
        return self.dataloader

