HOSTS="ansible/hosts"
if [ -f "${HOSTS}" ]; then
    echo "${HOSTS} is a valid file";
else
    echo "${HOSTS} is not a valid inventory file";
    exit 1
fi
for workers in 16 24 32 48 64
    do
        ansible-playbook -i ansible/hosts ansible/browbeat/adjustment-workers.yml -e "workers=$workers"
        ansible-playbook -i ansible/hosts ansible/gather/site.yml
        source ~/browbeat-venv/bin/activate; ./browbeat.py rally
        deactivate
    done

