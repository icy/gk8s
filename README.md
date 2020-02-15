## Description

Scripting-friendly tool to work with multiple k8s clusters.

## Ideas

The known way

```
$ export KUBECONFIG=~/.kube/config:~/.kube/kubconfig2
$ kubectl config use-context my-context
$ kubectl get nodes
```

This new way

```
$ gk8s :my-cluster get nodes
```

## How it works

For each cluster, we provision its seperated/isolated
environment in `$GK8S_HOME/<cluster>`, which would be used
as a new `$HOME` directory.

Working with the cluster is simply by invoking

```
$ gk8s :<cluster> command-and-or-arguments
```

for example

```
$ gk8s :production get pods
```

would look up configuration in `~/.config/gk8s/production/.kube/config`
and execute the command `kubectl get pods` accordingly.

`GK8S_HOME` is `~/.config/gk8s` by default.

## Using this program as a script

Read more at https://blog.rapid7.com/2016/08/04/build-a-simple-cli-tool-with-golang/

```
$ go get github.com/erning/gorun
$ sudo mv ~/go/bin/gorun /usr/local/bin/
$ echo ':golang:E::go::/usr/local/bin/gorun:OC' | sudo tee /proc/sys/fs/binfmt_misc/register
:golang:E::go::/usr/local/bin/gorun:OC
```

## Authors. License. Misc

The author is Ky-Anh Huynh.

This work is released under a MIT license.

This program is the `Golang` version of my Bashy thing
https://github.com/icy/bashy/blob/master/bin/gk8s.
New version is written as an answer to the known problem:
`Someone really hates Bash` :)
