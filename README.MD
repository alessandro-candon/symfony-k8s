# Symfony k8s gcp-autopilot

First of all :

1) create a GCP Project
2) login : ` gcloud auth login`
3) set project as default : `gcloud config set project <project-name>`  


0 cost hosted project on GCP with K8s-autopilot.





0 cost hosted prohect on GCP with cloud run

1) create autopilot cluster on GCP
2) buld phpfpm image `docker run -p 8080:8080 -it --rm gcr.io/dnmz-dimostration/symfony-cloudrun`
3) push the image : `docker push gcr.io/dnmz-dimostration/symfony-cloudrun`
4) deploy on cloud run : `gcloud run deploy symfony --image gcr.io/dnmz-dimostration/symfony-cloudrun --region europe-west4 --platform managed --allow-unauthenticated --memory 1G`


