import json
import ast
import re


def read_data_from_file(filename):
    with open(filename, 'r') as file:
        data_lines = file.readlines()  # Read all lines from the file
    return data_lines


def getlabel2(label2_counts):
    label2_counts = json.loads(label2_counts)
    totLen = len(label2_counts)
    if totLen > 3:
        totLen = 3

    # Find the label2 with the maximum count
    max_label2 = max(label2_counts, key=label2_counts.get)
    #sorted_label2 = sorted(label2_counts, key=label2_counts.get, reverse=True)[:totLen]
    return max_label2,label2_counts


def writeIndexToNewLabel(labelFile, imagenet1k_label_file, properLabelFile):
    with open(labelFile, 'r') as file:
        file_content = file.read()
        try:
            label_dict = ast.literal_eval(file_content)
        except (ValueError, SyntaxError) as e:
            print("Error parsing the content:", e)

    with open(imagenet1k_label_file, 'r') as f:
        labels = [int(line.strip()) for line in f.readlines()]

    with open(properLabelFile, 'w') as file:
        for label in labels:
            file.write(label_dict[label]+'\n')



def find_accuracy(filenameList, labelFile):
    dataLines = []
    correct_predictions = []
    total_predictions = 0

    with open(labelFile, 'r') as file:
        file_content = file.read()
        try:
            label_dict = ast.literal_eval(file_content)
        except (ValueError, SyntaxError) as e:
            print("Error parsing the content:", e)

    for file in filenameList:
        dataLines.append(read_data_from_file(file))
        correct_predictions.append(0)

    for idx1 in range(1000):
        label1 = -1
        label2_counts = []
        for _ in range(len(filenameList)):
            label2_counts.append(0)

        for idx2 in range(len(filenameList)):
            label1, label2_counts[idx2] = dataLines[idx2][idx1].split(":", maxsplit=1)
            label1 = int(label1)
            _, label2_counts[idx2] = getlabel2(label2_counts[idx2])

        newlabel2 = label_dict[label1]
        total_predictions += sum(label2_counts[0].values())

        for idx3 in range(len(filenameList)):
            correct_predictions[idx3] += label2_counts[idx3].get(newlabel2, 0)

        newlabel2 = int(newlabel2)

    # Step 4: Calculate accuracy
    accuracy = [(correct / total_predictions) * 100 for correct in correct_predictions]
    print("Accuracy:", accuracy, "%")


def get_mapping(filenameList):
    dataLines = []
    correct_predictions = []

    for file in filenameList:
        dataLines.append(read_data_from_file(file))
        correct_predictions.append(0)

    label_mappings = {}
    rev_label_mappings = {}
    total_predictions = 0

    #for line in data_lines:
    #for idx1 in range(114, 116):
    for idx1 in range(1000):
        label2List = {}
        label1 = -1
        label2_counts = []
        for _ in range(len(filenameList)):
            label2_counts.append(0)

        for idx2 in range(len(filenameList)):
            label1, label2_counts[idx2] = dataLines[idx2][idx1].split(":", maxsplit=1)
            label1 = int(label1)

            label2,label2_counts[idx2] = getlabel2(label2_counts[idx2])

            """
            if label2 not in label2List:
                label2List[label2] = label2_counts[idx2][label2]
            else:
                label2List[label2] += label2_counts[idx2][label2]
                
        newlabel2 = max(label2List, key=label2List.get)
        """

        unified_dict = {}
        for d in label2_counts[:2]:
            for key, value in d.items():
                if key in unified_dict:
                    unified_dict[key] += value  # Sum if the key already exists
                else:
                    unified_dict[key] = value

        newlabel2 = max(unified_dict, key=unified_dict.get)

        label_mappings[label1] = newlabel2
        total_predictions += sum(label2_counts[0].values())

        for idx3 in range(len(filenameList)):
            correct_predictions[idx3] += label2_counts[idx3][newlabel2]

        newlabel2 = int(newlabel2)
        if newlabel2 in rev_label_mappings:
            print(f'{newlabel2} with label {label1} already exists for {rev_label_mappings[newlabel2]}')
        else:
            rev_label_mappings[newlabel2] = label1


    # Step 4: Calculate accuracy
    accuracy = [(correct / total_predictions) * 100 for correct in correct_predictions]
    print("Label Mappings:", label_mappings)
    print("Accuracy:", accuracy, "%")
    for idx in range(1000):
        if idx not in rev_label_mappings:
            print(f'{idx} is not found in rev map')


# One time to write imagenet label to model label index conversion
"""
filenameList = ["C:\\Users\\bistp\\Downloads\\CLass\\AdvHardML\\HW1_b\\ViT\\model\\volo_d4_448.txt",
                "C:\\Users\\bistp\\Downloads\\CLass\\AdvHardML\\HW1_b\\ViT\\model\\FDViT_B_norm_label.txt",
                "C:\\Users\\bistp\\Downloads\\CLass\\AdvHardML\\HW1_b\\ViT\\model\\FDViT_norm_label.txt"]

#get_mapping(filenameList)
labelFile = "C:\\Users\\bistp\\Downloads\\CLass\\AdvHardML\\HW1_b\\ViT\\model\\ImageToModelMap.txt"
imagenet1k_label_file = 'D:\\ImageNet\\ILSVRC2012_devkit_t12\\ILSVRC2012_devkit_t12\\data\\ILSVRC2012_validation_ground_truth.txt'
properLabelFile = "C:\\Users\\bistp\\Downloads\\CLass\\AdvHardML\\HW1_b\\ViT\\model\\proper_label.txt"
#find_accuracy(filenameList, labelFile)
writeIndexToNewLabel(labelFile, imagenet1k_label_file, properLabelFile)
"""

# Function to parse the file and store execution times in a dictionary
def parse_execution_times(file_path):
    execution_times = {}  # Dictionary to store the results

    # Open and read the file
    with open(file_path, 'r') as file:
        # Variable to store the prefix (e.g., FDViT, Deit, Pit)
        current_prefix = None

        for line in file:
            # Look for the line containing "Execution time" using regex
            match = re.search(r'(\w+)\s+Execution\s+time:\s+([0-9\.]+)\s+seconds', line)
            if match:
                # Extract prefix and execution time from the matched line
                current_prefix = match.group(1)  # e.g., "FDViT"
                execution_time = float(match.group(2))  # e.g., 47.36188179999999
                # Store in dictionary
                count = 1
                if current_prefix in execution_times:
                    execution_time += execution_times[current_prefix][0]
                    count += execution_times[current_prefix][1]

                execution_times[current_prefix] = [execution_time, count]

    for key,value in execution_times.items():
        execution_times[key] = execution_times[key][0]/execution_times[key][1]
    return execution_times
