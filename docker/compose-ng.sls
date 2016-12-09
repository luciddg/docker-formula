{%- from "docker/map.jinja" import compose with context %}
{%- for name, container in compose.items() if 'image' in container %}
  {%- set id = container.container_name|d(name) %}
  {%- set required_containers = [] %}
{{id}} image:
  dockerng.image_present:
    - name: {{container.image}}
    - insecure_registry: True

{{id}} container:
  dockerng.running:
    - name: {{id}}
    - image: {{container.image}}
  {%- if 'command' in container %}
    - command: {{container.command}}
  {%- endif %}
  {%- if 'environment' in container and container.environment is iterable %}
    - environment:
    {%- for env in container.environment %}
        - {{env}}
    {%- endfor %}
  {%- endif %}
  {%- set port_bindings = [] %}
  {%- if 'ports' in container and container.ports is iterable %}
    - ports:
    {%- for port in container.ports %}
      {%- if port is string %}
        {%- set port_binding = port.split(':', 2) %}
      - "{{ port_binding[-1] }}"
        {%- if port_binding|length > 1 %}
          {%- do port_bindings.append(port) %}
        {%- endif %}
      {%- else %}
      - "{{ port }}"
      {%- endif %}
    {%- endfor %}
  {%- endif %}
  {%- if port_bindings %}
    - port_bindings:
    {%- for port_binding in port_bindings %}
      - {{port_binding}}
    {%- endfor %}
  {%- endif %}
  {%- if 'volumes' in container %}
    - volumes:
    {%- for volume in container.volumes %}
      - {{volume}}
    {%- endfor %}
  {%- endif %}
  {%- if 'binds' in container %}
    - binds:
    {%- for bind in container.binds %}
      - {{bind}}
    {%- endfor %}
  {%- endif %}
  {%- if 'volumes_from' in container %}
    - volumes_from:
    {%- for volume in container.volumes_from %}
      {%- do required_containers.append(volume) %}
      - {{volume}}
    {%- endfor %}
  {%- endif %}
  {%- if 'links' in container %}
    - links:
    {%- for link in container.links %}
      {%- set name, alias = link.split(':',1) %}
      {%- do required_containers.append(name) %}
      - {{name}}:{{alias}}
    {%- endfor %}
  {%- endif %}
  {%- if 'restart' in container %}
    - restart_policy: {{ container.restart }}
  {%- endif %}
    - require:
      - dockerng: {{id}} image
  {%- if required_containers is defined %}
    {%- for containerid in required_containers %}
      - dockerng: {{containerid}}
    {%- endfor %}
  {%- endif %}
{% endfor %}
