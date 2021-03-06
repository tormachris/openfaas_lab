sudo git clone https://github.com/openfaas/faas-netes
sudo kubectl apply -f https://raw.githubusercontent.com/openfaas/faas-netes/master/namespaces.yml
cd faas-netes
#temporary fix, till faas-netes not gets gateway version 0.9.8, issue with autoscaling, issue #931
sed -i 's/ image: openfaas\/gateway:0.9.7/ image: openfaas\/gateway:0.9.8/' yaml/gateway-dep.yml

#enabling basic auth on gateway
export GW_PASS=$(head -c 16 /dev/random |shasum | cut -d ' ' -f1)
kubectl create secret generic gateway-basic-auth -n openfaas --from-literal=basic-auth-user=admin --from-literal=basic-auth-password=$GW_PASS
kubectl create secret generic basic-auth-user -n openfaas-fn --from-literal=basic-auth-user=admin
kubectl create secret generic basic-auth-password -n openfaas-fn --from-literal=basic-auth-password=$GW_PASS
sed -i '/\        - name: basic_auth/!b;n;c\          value: "true"' yaml/gateway-dep.yml
sed -i '/\        - name: basic_auth/!b;n;c\          value: "true"' yaml/queueworker-dep.yml
sed -i '56i\        volumeMounts: \n        - name: gateway-basic-auth \n          readOnly: true \n          mountPath: "/etc/openfaas"\n' yaml/gateway-dep.yml
#printf "        volumeMounts: \n        - name: gateway-basic-auth \n          readOnly: true \n          mountPath: "/etc/openfaas"\n" >> yaml/gateway-dep.yml
printf '      volumes:\n      - name: gateway-basic-auth\n        secret:\n          secretName: gateway-basic-auth\n' >> yaml/gateway-dep.yml 
printf '\n        volumeMounts: \n        - name: gateway-basic-auth \n          readOnly: true \n          mountPath: "/etc/openfaas"\n' >> yaml/queueworker-dep.yml
printf '      volumes:\n      - name: gateway-basic-auth\n        secret:\n          secretName: gateway-basic-auth\n' >> yaml/queueworker-dep.yml
sed -i '/\        - name: scale_from_zero/!b;n;c\          value: "true"' yaml/gateway-dep.yml
sudo kubectl apply -f ./yaml
cd ..

