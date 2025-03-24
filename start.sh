echo "setting up environment"

cd argocd; skaffold run; cd ..;
#kubectl port-forward svc/argocd-server -n argocd 8080:443
