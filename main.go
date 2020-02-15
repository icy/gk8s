/*
  Purpose : a wrapper of k8s
  Author  : Ky-Anh Huynh
  License : MIT
  Date    : 2020-02-15
*/

package main

import "fmt"
import "os"
import "os/exec"
import "strings"
import "path/filepath"
import "syscall"

func log2(msg string) {
	fmt.Fprintf(os.Stderr, msg)
}

func log2exit(retval int, msg string) {
	log2(msg)
	os.Exit(retval)
}

func args2cmd(args []string) (string, []string) {
	command := "foo"
	if len(args) == 0 {
		command = "noop"
		return command, []string{""}
	}

	if args[0] == "--" {
		if len(args) > 1 {
			command = args[1]
			args = args[1:]
		} else {
			command = "noop"
			return command, []string{""}
		}
	} else {
		if strings.Index(args[0], "kubectl") == -1 {
			command = "kubectl"
			args = append([]string{command}, args...)
		} else {
			command = args[0]
		}
	}

	binary, err := exec.LookPath(command)
	if err != nil {
		log2exit(1, fmt.Sprintf(":: Command not found %s\n", command))
	}

	for _, arg := range args {
		if arg == "delete" {
			if _, err := os.Stat(".delete"); os.IsNotExist(err) {
				log2exit(1, ":: Error: File .delete doesn't exist in the current directory.\n")
			} else {
				err := os.Remove(".delete")
				if err != nil {
					log2exit(1, fmt.Sprintf(":: Error: %s.\n", err))
				} else {
					log2(":: File .delete was removed.\n")
				}
			}
			break
		}
	}

	return binary, args
}

func main() {
	if len(os.Args) < 2 {
		log2exit(1, ":: Error: Cluster name (or context) is required.\n")
	}

	cluster_name := os.Args[1]
	if cluster_name[0:1] != ":" {
		log2exit(1, fmt.Sprintf(":: Error: Cluster name (context) must be prefixed with `:', e.g., gk8s :%s.\n", cluster_name))
	}
	if len(cluster_name) == 1 {
		log2exit(1, ":: Error: Cluster name is not provided.\n")
	}
	cluster_name = cluster_name[1:]

	config_dir := os.Getenv("GK8S_HOME")
	kubecfg := "foo"
	if len(config_dir) > 0 {
		kubecfg = filepath.Join(config_dir, cluster_name)
	} else {
		old_home := os.Getenv("HOME")
		kubecfg = filepath.Join(old_home, ".config/gk8s/", cluster_name)
	}

	binary, args := "foo", []string{"bar"}
	/* cluster name is provided, but nothing else */
	if len(os.Args) == 2 {
		binary = "noop"
	} else {
		binary, args = args2cmd(os.Args[2:])
	}

	if binary == "noop" {
		log2exit(0, ":: noop command does nothing.\n")
	}

	os.Setenv("KUBECONFIG", kubecfg)
	log2(fmt.Sprintf(":: Executing '%s', args: %v, KUBECONFIG: %s\n", binary, args, kubecfg))
	err := syscall.Exec(binary, args, syscall.Environ())
	if err != nil {
		log2exit(1, fmt.Sprintf(":: Error: %v.\n", err))
	}
}
