
kubectl delete crd clusterimagepolicies.portieris.cloud.ibm
kubectl delete crd imagepolicies.portieris.cloud.ibm.com
kubectl delete validatingwebhookconfiguration --all
kubectl delete mutatingwebhookconfiguration --all
kubectl delete namespace portieris
kubectl delete secret portieris
kubectl delete secret delegation-pubkey

rm -fr /tmp/portieris
mkdir /tmp/portieris
cd /tmp/portieris

wget https://github.com/IBM/portieris/releases/download/v0.12.0/portieris-v0.12.0.tgz
tar xzvf portieris-v0.12.0.tgz
sh ./portieris/gencerts portieris
sed -i 's|ibm-system|{{ .Release.Namespace }}|g' portieris/templates/policies.yaml
helm install portieris --create-namespace --namespace portieris --set IBMContainerService=false --debug ./portieris
kubectl create secret generic delegation-pubkey --from-file=publicKey=/Users/dwake/gitclient/grumpy/notary/delegation.crt --from-literal=name=releases

cat <<EOF > policy.yaml
apiVersion: portieris.cloud.ibm.com/v1
kind: ImagePolicy
metadata:
  name: pinned-notary-server
spec:
   repositories:
    - name: "*"
      policy:
        trust:
          enabled: true
          trustServer: https://notaryserver.jfrog.com:443
          signerSecrets:
          - name: delegation-pubkey

EOF

kubectl apply -f policy.yaml
