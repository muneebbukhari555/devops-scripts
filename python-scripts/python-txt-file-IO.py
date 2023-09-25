import ruamel.yaml
import argparse

parser = argparse.ArgumentParser(description='Reading Keycloak client Details from Customer Props file for keycloak Helmsman configmap')

# Add arguments with flags
parser.add_argument("-f", "--args1", help='Please input the filename by using -f option. This is mandatory!')
# Parse the command-line arguments
args = parser.parse_args()
# Access the values of the arguments
filename = "solution-details.props"

# Example usage
customer_file_path = f"helmsman/keycloak/customer/solutions/{filename}"
print(f"Customer file path used is: {customer_file_path}")
search_string = '#Keycloak_Client_List'

def find_lines_after_string(file_path, search_string):
    matched_lines = []
    num_lines_after =20

    with open(file_path, 'r') as file:
        lines = file.readlines()

    for line_number, line in enumerate(lines, start=1):
        if search_string in line:
            # Add the matched line and subsequent lines
            matched_lines.extend(lines[line_number:line_number+num_lines_after])

    return matched_lines


matched_lines = find_lines_after_string(customer_file_path, search_string)
client_list = [item.strip() for item in matched_lines]
print(client_list)


cm_filepath = './configmap-template.yaml'
cm_filepath_new = './configmap-clients.yaml'
yaml = ruamel.yaml.YAML()
with open(cm_filepath, 'r') as file:
    existing_data = yaml.load(file)

existing_data['data']['defaultservicelist.txt'] = '\n'.join(client_list)

with open(cm_filepath_new, 'w') as file:
    yaml.dump(existing_data, file)