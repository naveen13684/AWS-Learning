#!/bin/sh

kdb="https://raw.githubusercontent.com/kubernetes/dashboard/v1.10.1/src/deploy/recommended/kubernetes-dashboard.yaml"
heapster="https://raw.githubusercontent.com/kubernetes/heapster/master/deploy/kube-config/influxdb/heapster.yaml"
influxdb="https://raw.githubusercontent.com/kubernetes/heapster/master/deploy/kube-config/influxdb/influxdb.yaml"
heapsterrbacc="https://raw.githubusercontent.com/kubernetes/heapster/master/deploy/kube-config/rbac/heapster-rbac.yaml"

/usr/bin/cat > eks-dashboard-service-account.yaml << EOF
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: cluster-view
rules:
- apiGroups:
  - '*'
  resources:
  - '*'
  verbs:
  - list
  - get
  - watch
- nonResourceURLs:
  - '*'
  verbs:
  - get

---

apiVersion: v1
kind: ServiceAccount
metadata:
  name: eks-dashboard
  namespace: kube-system

---

apiVersion: rbac.authorization.k8s.io/v1beta1
kind: ClusterRoleBinding
metadata:
  name: eks-dashboard
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cluster-view
subjects:
- kind: ServiceAccount
  name: eks-dashboard
  namespace: kube-system
EOF


#/usr/bin/kubectl apply -f "kdb" && "heapster" && "influxdb" &&  "heapsterrbacc" &&  "eks-dashboard-service-account.yaml"
/usr/bin/kubectl apply -f "$kdb"
/usr/bin/kubectl apply -f "$heapster"
/usr/bin/kubectl apply -f "$influxdb"
/usr/bin/kubectl apply -f "$heapsterrbacc"
/usr/bin/kubectl apply -f "/root/dashboard/eks-dashboard-service-account.yaml"

echo Enabling Port-Forwarding for Dashboard. 


nohup /usr/bin/kubectl port-forward svc/kubernetes-dashboard -n kube-system 6443:443 & 

exit 0
