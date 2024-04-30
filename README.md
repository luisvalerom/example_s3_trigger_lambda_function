# Proyecto de ejemplo, AWS Lambda Function, S3, GLUE, Terraform

![images/Diagrama%20S3%20Lambda%20Function.jpg](images/Diagrama%20S3%20Lambda%20Function.jpg)


En este proyecto configuraremos un *Bucket S3* que activara automáticamente una *Lambda Function* cada vez que se escriba un nuevo objeto en el. En la *Lambda Function* vamos a hacer uso de una biblioteca *Python* de código abierto llamada *AWS Data Wrangler* creada por *AWS*, usaremos esta biblioteca para convertir un archivo *CSV* al formato *Parquet* y luego
actualizar el catálogo de datos de *AWS Glue*.

Para gestionar nuestra infraestructura utilizaremos *Terraform*

## Punto de inicio

- [Terraform CLI](https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli) instalado.
- [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html) instalado.
- Cuenta de *AWS* y credenciales asociadas que permitan la creación de recursos.

Necesitaremos crear un *Lambda Layer*, para lo cual nos apoyaremos en un *Bucket S3* donde tendremos previamente cargadas las librerías y demás utilidades que requeriremos en los diferentes proyectos.

## Despliegue

Para inicializar el proyecto, que consiste en descargar e instalar el *Provider* que permite a *Terraform* interactuar con *AWS* debemos ejecutar: `terraform init`

Podemos visualizar que acciones realizaría *Terraform* para aplicar nuestra configuración actual, sin ajecutar dichas acciones aún: `terraform plan`

Para aplicar las configuraciones y crear los recursos debemos ejecutar el siguiente comando, debemos sustituir el nombre del *Bucket* en el cual residen nuestras librerías y utilidades: `terraform apply -var s3_bucket_file_layer=<Utils Bucket name> -var s3_key_file_layer=awswrangler-layer-2.10.0-py3.8.zip`

Ya con nuestra infraestructura desplegada procedemos a verificar que todo funciona como esperamos, podemos copiar un archivo a nuestro *Bucket* "Landing Zone" con el siguiente comando: `aws s3 cp data/test.csv s3://<Landing Zone Bucket>/testdb/csvparquet/test.csv`

Para finalizar, es importante no olvidar eliminar todos los recursos creados con este proyecto y evitarnos problemas con los costos que se puedan generar, para esto ejecutamos: `terraform destroy`

