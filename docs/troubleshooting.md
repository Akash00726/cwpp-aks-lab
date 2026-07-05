LAB 4 - Config-map

Objective: What you wanted to achieve.
Architecture: Deployment → ReplicaSet → Pods → Service → ConfigMap.
Commands Used: kubectl apply, kubectl describe, kubectl exec, printenv, etc.
Incident: The environment variables were blank because render_template() wasn't passing them to the template.
Root Cause: Application code issue, not a Kubernetes issue.
Resolution: Updated render_template(), rebuilt the image, loaded it into Kind, and rolled out the new Deployment.
Key Takeaways: Always verify each layer (application, container, Kubernetes) before assuming where the fault lies.