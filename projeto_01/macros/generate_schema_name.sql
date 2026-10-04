{% macro generate_schema_name(custom_schema_name, node) -%}
    {#- Usa o schema configurado exatamente como está (silver, gold...) em vez de <target>_<schema> -#}
    {%- if custom_schema_name is none -%}
        {{ target.schema }}
    {%- else -%}
        {{ custom_schema_name | trim }}
    {%- endif -%}
{%- endmacro %}
