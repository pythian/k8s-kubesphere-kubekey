import yaml

def load_yaml(filename):
    with open(filename, 'r') as f:
        return list(yaml.safe_load_all(f))

original = load_yaml('deployment-kubesphere.yml')
updated = load_yaml('updated-kubesphere.yml')

# Assuming the number of documents in both files are the same
are_identical = True
for orig_doc, updated_doc in zip(original, updated):
    # Making a deep copy of the dictionaries for comparison
    orig_doc_copy = yaml.safe_load(yaml.dump(orig_doc))
    updated_doc_copy = yaml.safe_load(yaml.dump(updated_doc))

    # Remove the 'hosts' and 'roleGroups' from both to skip their comparison
    orig_doc_copy.get('spec', {}).pop('hosts', None)
    orig_doc_copy.get('spec', {}).pop('roleGroups', None)

    updated_doc_copy.get('spec', {}).pop('hosts', None)
    updated_doc_copy.get('spec', {}).pop('roleGroups', None)

    # If after removing the 'hosts' and 'roleGroups' they aren't the same, set the flag to False
    if orig_doc_copy != updated_doc_copy:
        are_identical = False
        break

if are_identical:
    print("The files are structurally identical except for the 'hosts' and 'roleGroups' changes.")
else:
    print("The files have other structural differences.")
