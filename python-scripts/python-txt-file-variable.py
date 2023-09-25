import ruamel.yaml
import argparse
import ast
parser = argparse.ArgumentParser(description='Reading Keycloak client Details from Customer Props file for keycloak Helmsman configmap')

# Add arguments with flags
parser.add_argument("-f", "--args1", help='Please input the filename by using -f option. This is mandatory!')
# Parse the command-line arguments
args = parser.parse_args()
# Access the values of the arguments
filename = args.args1
variable_name = 'Keycloak_Client_List'
def get_variable_value(file_path, variable_name):
    with open(file_path, "r") as data:
        content = data.read()

    variable_value = None
    for line in content.split('\n'):
        if line.startswith(variable_name):
            variable_value = line.split('=')[1].strip()
            break

    return variable_value

print(f"Customer file path used is: {filename}")

string_variable = get_variable_value(filename, variable_name)
print(f"File include Keycloak clients are: {string_variable}")
client_list = ast.literal_eval(string_variable)


cm_filepath = './configmap-template.yaml'
cm_filepath_new = './configmap-clients.yaml'
yaml = ruamel.yaml.YAML()
with open(cm_filepath, 'r') as file:
    existing_data = yaml.load(file)

existing_data['data']['defaultservicelist.txt'] = '\n'.join(client_list)

with open(cm_filepath_new, 'w') as file:
    yaml.dump(existing_data, file)