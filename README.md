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

The tool doesn't accept delete action by default. You must touch a local
file `.delete` before continue:

```
$ gk8s :my-cluster delete pod foo
:: Error: File .delete doesn't exist in the current directory.

$ touch .delete; gk8s :my-cluster delete pod foo
Error from server (NotFound): pods "foo" not found
```

## Why

* Improve communication
* Easy to write examples in documentation
* Design for scripting purpose
* Slow down dangerous commands by default
* Having fun with `Golang`

## Getting started

```
$ mkdir -pv ~/.config/gk8s/my-cluster/.kube/
$ ln -sv /path/to/cluster-config ~/.config/gk8s/my-cluster/.kube/config

 # If you are using EKS, create some link for credentials
$ ln -s ~/.aws ~/.config/gk8s/my-cluster/.aws
```

Repeat the steps for any other cluster.

## How it works

For each cluster, we provision its seperated/isolated
environment in `$GK8S_HOME/<cluster>`
(`GK8S_HOME` is `~/.config/gk8s` by default),
which would be used as a new `$HOME` directory.

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

Each cluster requires its own home directory. This may be a bit
convenient and it requires a lot more disk space when `helm` is used.
However, this may be helpful in the future (`FIXME`).

## Examples

The following commands yield the same result:

```
$ gk8s :cluster get nodes
$ gk8s :cluster kubectl get nodes
$ gk8s :cluster -- kubectl get nodes
```
The command `kubectl` is used by defualt.
When you specify `--`, the remain part is invoked.

If you want to use with `helm`:

```
$ gk8s :cluster -- helm <additional-arguments>
```

## Using this program as a script

Read more at https://blog.rapid7.com/2016/08/04/build-a-simple-cli-tool-with-golang/

```
$ go get github.com/erning/gorun
$ sudo mv ~/go/bin/gorun /usr/local/bin/
$ echo ':golang:E::go::/usr/local/bin/gorun:OC' | sudo tee /proc/sys/fs/binfmt_misc/register
:golang:E::go::/usr/local/bin/gorun:OC
```

## Alternatives

You can use some shell script, some aliases, bla bla.
You can also write a simple function to update `KUBECONFIG` variable
for your cluster before getting started, for example, in `.bash`:

```
$ my_gk8s() {
  cluster="${1:-}"
  if [[ "${cluster:0:1]}" == ":" ]]; then
    cluster="${cluster:1}"
    shift
  else
    echo >&2 ":: Missing cluster name."
    return
  fi
  export KUBECONFIG="~/.config/gk8s/$cluster"
  kubectl "$@"
}

$ my_gk8s :my-cluster get pods
```

## Authors. License. Misc

The author is Ky-Anh Huynh.

This work is released under a MIT license.

This program is the `Golang` version of my Bashy thing
https://github.com/icy/bashy/blob/master/bin/gk8s.
New version is written as an answer to the known problem:
`Someone really hates Bash` :)
