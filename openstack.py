import sys
import json
import pprint
import os
import jinja2
sys.path.append('/home/smalleni/quads/lib')
import Quads


# TODO(sai): Make these priorities dynamic based on Ansible facts
controller_priority={}
compute_priority={}
ceph_priority={}

controller_priority['r930'] = 100
controller_priority['r730'] = 90
controller_priority['r630'] = 50
controller_priority['r620'] = 30
controller_priority['6048r'] = 20
controller_priority['6018r'] = 10
# ceph priorities
ceph_priority['r930'] = 90
ceph_priority['r730'] = 50
ceph_priority['r630'] = 20
ceph_priority['r620'] = 10
ceph_priority['6048r'] = 100
ceph_priority['6018r'] = 10

# compute priorities
compute_priority['r930'] = 10
compute_priority['r730'] = 20
compute_priority['r630'] = 90
compute_priority['r620'] = 100
compute_priority['6048r'] = 50
compute_priority['6018r'] = 70



# TODO(sai): these values for total node count should be passed to the script
inventory = {}
inventory['r930'] = 2
inventory['r730'] = 0
inventory['r630'] = 2
inventory['r620'] = 8
inventory['6048r'] = 0
inventory['6018r'] = 0

composable_role = {}
composable_role['control'] = 0
composable_role['r620compute'] = 0
composable_role['r630compute'] = 0
composable_role['r730compute'] = 0
composable_role['6048rcompute'] = 0
composable_role['6018rcompute'] = 0
composable_role['r930compute'] = 0
composable_role['r620ceph'] = 0
composable_role['r630ceph'] = 0
composable_role['r730ceph'] = 0
composable_role['6048rceph'] = 0
composable_role['6018rceph'] = 0
composable_role['r930ceph'] = 0



def sort_priority(priority_dict):
    priority_list = sorted(priority_dict.items(), key=lambda x: x[1], reverse=True)
    return priority_list



def schedule_nodes(count, priority, role=None):
    systems = {}
    filter = sort_priority(priority)
    if sum(inventory.values()) < count:
        sys.exit(1)
    # NOTE(sai): we need role_minimum as controller node is not composable and we
    # need to check if a minimum of 3 nodes if that node type is to be scheduled
    # as controllers
    role_minimum = 2 if role == 'control' else 0
    for i in range(0, count):
        for type, weight in filter:
            if inventory[type] > role_minimum:
                systems[type] = systems.get(type, 0) + 1
                inventory[type] -= 1
                break
    return systems


def load_json(fname):
    with open(fname) as instack_file:
        instack_data = json.load(instack_file)
    return instack_data
    #print instack_data['nodes']

def tag_instack(instack_data, nodes, role):
    for type, count in nodes.items():
        node_index = 0
        i = 0
        for machine in instack_data['nodes']:
        #TODO(sai): remove ugly hack to get node type, have node type as a filed
        # in instackenv.json populated during initial creation itself 
            machine_type = machine['pm_addr'].split('-')[3].split('.')[0]
            if ( 'name' not in machine and machine_type in nodes and
            nodes[machine_type] > 0  and type == machine_type):
                if role == 'control':
                    machine['name'] = role + '-' + str(node_index)
                    composable_role[role]+=1
                else:
                    machine['name'] = machine_type + role + '-' + str(node_index)
                    composable_role[machine_type+role]+=1
                node_index = node_index + 1
                nodes[machine_type] -= 1
    dump_json(instack_data)

def dump_json(instack_data):
    with open('sai.json', 'w') as instack_file:
        json.dump(instack_data, instack_file, indent=4)

def render(tpl_path, context):
    path, filename = os.path.split(os.path.abspath(os.path.expanduser(tpl_path)))
    jinja_env = jinja2.Environment(loader=jinja2.FileSystemLoader(path))
    return jinja_env.get_template(filename).render(context)

def main():
    controller_nodes = schedule_nodes(3, controller_priority, 'control')
    ceph_nodes = schedule_nodes(3, ceph_priority)
    compute_nodes = schedule_nodes(0, compute_priority)
    print controller_nodes
    print ceph_nodes
    print compute_nodes
    instack_data = load_json('cloud06_instackenv.json.1')
    tag_instack(instack_data, controller_nodes, 'control')
    instack_data = load_json('sai.json')
    tag_instack(instack_data, ceph_nodes, 'ceph')
    context = {'controller': composable_role['control']}
    with open('sai.template', 'w') as f:
        result = render('/home/smalleni/deploy.yaml', context)
        f.write(result)



if __name__ == '__main__':
    sys.exit(main())



