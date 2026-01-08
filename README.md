![icy](https://github.com/icy/gk8s/workflows/icy/badge.svg)

## TOC

* [Description](#description)
* [Ideas](#ideas)
* [Why](#why)
* [Why don't just use kubectl config](#seriously-why-dont-just-use-kubectl-config)
* [Getting started](#getting-started)
* [Version information](#version-information)
* [Examples](#examples)
* [Too many clusters](#too-many-clusters)
* [How it works](#how-it-works)

## Description

Scripting-friendly tool to work with multiple k8s clusters, with ability to provide a concise way
to write system documentation, to avoid human mistake and finally, to improve team communication and work.

## Ideas

The known way

```
$ export KUBECONFIG=~/.kube/config:~/.kube/kubconfig2
$ kubectl config use-context my-context
$ kubectl get nodes
$ kubectl --context=foo get nodes
$ helm --kube-context=foo list
$ custom-command --custom-option-to-fetch-kubeconfig-and-context
```

This new way

```
$ gk8s :my-cluster get nodes
$ gk8s :my-cluster helm list
$ gk8s :my-cluster -- helm list
$ gk8s :my-cluster -- custom-command   # KUBECONFIG will be set accordingly with default context!
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
* Easily trace important command from history

## Seriously, why don't just use `kubectl config`

* `$ kubectl config set-cluster foo` can return happily (aka, without any error)
* `$ kubectl config set-context foo` can return happily (aka, without any error)
* `$ kubectl foo --context=foo` is great but if you don't use `kubectl` you need to remember another option e.g. `kube-context` (Helm)
* `export KUBECONFIG` is long, error-prone

You may shoot yourself in the foot with shared `kubectl` configuration files.
And having multiple clusters, contexts in the same `~/.kubectl/[config]` is
not easy.

And your friend or team mate hardly replicates your command on their laptop
because they may have wrong/invalid/different `KUBECONFIG`.

Using external configuration gives you neutral knowledge about your
history. For example

```
$ history | grep kubectl
kubectl get pods ...
kubectl edit deployment ...
```

You get no idea of the cluster on which you executed the command(s).

* `Updated on July 2021`: This topic is also discussed on HN: https://news.ycombinator.com/item?id=27739134

## Getting started

Starting from v1.1.1, you can download binary files generated automatically
by Github-Action (via goreleaser tool). You find the files from
the release listing page: https://github.com/icy/gk8s/releases

To install `gk8s` on your laptop by local compiling process, please try `go get`
or `go install`. In the following example, you may want to replace
`@latest` with any version found from the release page
(https://github.com/icy/gk8s/releases).

```
$ go install github.com/icy/gk8s@latest
$ export PATH=$PATH:"$(go env GOPATH)/bin"
```

Now prepare your configuration. It's important to note that
we don't like to put multiple cluster configurations in the same file.
That's possible, but this tool highly recommends to have seperated files
for each cluster:

```
$ mkdir -pv ~/.config/gk8s/
$ cp -fv /path/to/cluster-config ~/.config/gk8s/my-cluster
```

Repeat the last steps for any other cluster.

If you are using `EKS`, you use a script generator too:

```
$ aws eks update-kubeconfig \
  --profile some_profile_name \
  --name cluster_name \
  --alias cluster_alias \
  --region eu-west-1 \
  --dry-run
  >  ~/.config/gk8s/cluster_name
```

## Examples


## Version information

Show the build metadata from the current binary:

```
$ gk8s --version
```

The following commands yield the same result:

```
$ gk8s :cluster get nodes
$ gk8s :cluster kubectl get nodes
$ gk8s :cluster -- kubectl get nodes
```

Both `kubectl` and `helm` don't need any separator (`--`). The following
commands are the same:

```
$ gk8s :cluster helm list
$ gk8s :cluster -- helm list
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

Context switching? Environment variable? You would get quite a lot of
troubles here ;)

How to get list of nodes from multiple clusters?

```
$ parallel 'gk8s {} get nodes' ::: :cluster1 :cluster2 :cluster3
```

## Too many clusters

When you have multiple clusters, you can have multiple configurations
and it isn't convenient to have all configuration in the same file
and/or same directory.

It's very easy to organize multiple cluster configurations with `gk8s`.
Let's say you're using the default configuration path `$HOME/.config/gk8s`.
You can have directory structure as below

```
$HOME/.config/gk8s/
  org1/
    cluster1
    cluster2
  org2/
    cluster1
    cluster2
  all
    cluster11 --> ../org1/cluster1 (symlink)
    cluster12 --> ../org1/cluster2 (symlink)
    cluster21 --> ../org2/cluster1 (symlink)
    cluster22 --> ../org2/cluster2 (symlink)
```

Now everything is quite trivial with `gk8s`

```
$ gk8s :org1/cluster1   get nodes
$ gk8s :all/cluster11   get nodes
```

For mutiple user/context support, you may follow the same way;)

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

## Authors. License. Misc

The author is Ky-Anh Huynh.

This work is released under a MIT license.

This program is the `Golang` version of my Bashy thing
https://github.com/icy/bashy/blob/master/bin/gk8s.
New version is written as an answer to the known problem:
`Someone really hates Bash` :)
