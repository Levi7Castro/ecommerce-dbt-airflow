{% test valid_email(model, column_name) %}

-- Retorna as linhas cujo email não segue o formato nome@dominio.ext (nulos são ignorados)
select {{ column_name }}
from {{ model }}
where {{ column_name }} is not null
  and {{ column_name }} !~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$'

{% endtest %}
