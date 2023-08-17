import json
import yaml

# Load file created by kubekey named kubesphere, loaded into a yaml structure as a list of documents
with open('deployment-kubesphere.yml', 'r') as kubesphere_yaml_file:
        all_kubesphere_yaml_documents = list(yaml.safe_load_all(kubesphere_yaml_file))

# Convert that into a list of jsons for easier update
all_kubesphere_jsons = [json.dumps(doc) for doc in all_kubesphere_yaml_documents]

# Load file with updates to be made fromr yaml
with open('deployment-hosts.yml', 'r') as hosts_yaml_file:
        hosts_json_document = yaml.safe_load(hosts_yaml_file)

# Convert all_kubesphere_jsons back to a list of dictionaries
all_kubesphere_documents = [json.loads(doc) for doc in all_kubesphere_jsons]

# Extract the hosts and roleGroups data from hosts_json_document
hosts_data = hosts_json_document.get('spec', {}).get('hosts', [])
roleGroups_data = hosts_json_document.get('spec', {}).get('roleGroups', {})

# Iterate and update each document
for doc in all_kubesphere_documents:
        if 'spec' in doc:
            # Update hosts data if it exists in the current document
            if 'hosts' in doc['spec']:
                doc['spec']['hosts'] = hosts_data

            # Update roleGroups data if it exists in the current document
            if 'roleGroups' in doc['spec']:
                doc['spec']['roleGroups'] = roleGroups_data

# If you want to work with the updated documents in JSON format
#all_kubesphere_updated_jsons = [json.dumps(doc) for doc in all_kubesphere_documents]

with open('updated-kubesphere.yml', 'w') as output_file:
        for doc in all_kubesphere_documents:
            # Convert the dictionary to YAML format
            yaml_str = yaml.dump(doc)

            # Write the YAML content to the file and add the document separator
            output_file.write(yaml_str)
            output_file.write("---\n")  # Document separator
