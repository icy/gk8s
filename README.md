![icy](https://github.com/icy/gk8s/workflows/icy/badge.svg)

## Description

Scripting-friendly tool to work with multiple k8s clusters, with ability to provide a concise way
to write system documentation, to avoid human mistake and finally, to improve team communication and work.

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

The tool doesn't accept delete action by default.
You must touch a local file `.delete` or using environment setting `DELETE=true`
to activate the deletion:

```
$ gk8s :my-cluster delete pod foo
:: Error: File .delete doesn't exist in the current directory.

$ touch .delete; gk8s :my-cluster delete pod foo
Error from server (NotFound): pods "foo" not found

$ DELETE=true gk8s :my-cluster delete pod foo
Error from server (NotFound): pods "foo" not found
```

Touching file `.delete` doesn't support multiple actions in parallel.

## Why

* Improve communication
* Easy to write examples in documentation
* Design for scripting purpose with better error handling
* Slow down dangerous commands by default
* Have fun with `Golang`
* Somebody hates shell scripting :D
* Just don't have everything in `~/.kube/config`

## Seriously, why just use `kubectl config`

* `$ kubectl config set-cluster foo` can return happily (aka, without any error)
* `$ kubectl config set-context foo` can return happily (aka, without any error)
* `export KUBECONFIG` is long, error-prone

## Getting started

```
$ go get github.com/icy/gk8s
$ mkdir -pv ~/.config/gk8s/
$ ln -sv /path/to/cluster-config ~/.config/gk8s/my-cluster
```

Repeat the last steps for any other cluster.

## Examples

The following commands yield the same result:

```
$ gk8s :cluster get nodes
$ gk8s :cluster kubectl get nodes
$ gk8s :cluster -- kubectl get nodes
```

Some notes

* The command `kubectl` is used by default.
* When you specify `--`, the remained part of arguments is invoked.
  This is useful when you need to use Helm and/or to execute any other command
  within your k8s cluster context.
* If `cluster` is `local`, the default configuration is used
  (`$HOME/.kube/config`)

If you want to use with `helm`:

```
$ gk8s :cluster -- helm <additional-arguments>
```

Now let's work with multiple clusters on the same command: For example,
to compare configurations on two clusters, let's go with `diff`:

```
$ colordiff <(gk8s :cluster1 get foo -n bar -o yaml) <(gk8s :cluster2 get foo -n bar -o yaml)
```

Switching context? Environment variable? You would get quite a lot of
troubles here ;)

How to get list of nodes from multiple clusters?

```
$ parallel 'gk8s {} get nodes' ::: :cluster1 :cluster2 :cluster3
```

## How it works

Each cluster/context has their own configuration file under
the directory `$GK8S_HOME` (which is `~/.config/gk8s/` by default).
Working with the cluster is simply by invoking

```
$ gk8s :<cluster> command-and-or-arguments
```

for example

```
$ gk8s :production get pods
```

would look up configuration in `~/.config/gk8s/production`
and execute the command `kubectl get pods` accordingly.

If `cluster` is `local`, the command will set `KUBECONFIG=$HOME/.kube/config`.

If `KUBECONFIG` file not found, the tool exits immediately.

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
for your cluster before getting started, for example, in `.bash`.

(Note, the following script doesn't have advanced feature as the golang tool.)

```
$ my_gk8s() {
  cluster="${1:-}"
  if [[ "${cluster:0:1}" == ":" ]]; then
    cluster="${cluster:1}"
    shift
  else
    echo >&2 ":: Missing cluster name."
    return
  fi
  export KUBECONFIG="$HOME/.config/gk8s/$cluster"
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
