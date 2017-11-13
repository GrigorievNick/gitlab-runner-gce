# Auto-scaling Gitlab Runner in GCE

Few days ago I wanted to give the [Gitlab CI](https://about.gitlab.com/gitlab-ci/) a spin and came up with this solution to use
GCE as a scaling cluster for running the tests for different backend projects.
As the workers in this setup uses Docker, I can define in my projects CI configuration what kind of image I want to run my test on,
whether it is Node.JS, Python, etc. This is really great, as then I do not have to configure servers for each of the different
environments separately and scale those.

This repo contains a simple example setup of setting up an auto-scaling [Gitlab Runner](https://gitlab.com/gitlab-org/gitlab-ci-multi-runner) inside GCE.
We will setup a Runner using "docker+machine" -executor that runs in very minimalistic idle costs (~ $20USD/month).
We will also try to use Google Cloud Storage as the Runners cache.

In a nutshell this setup will do the following:

 1. Setup a g1-small instance to act as a Gitlab Runner
 2. Register this runner to your Gitlab instance
 3. Configure Docker Machine to spin up g1-small [Preemptible VMs](https://cloud.google.com/preemptible-vms/) as the workers.

## Preparations

First of all, you should have a Google Cloud -project setup with billing and Compute Engine enabled.
You should also have the Google Cloud SDK installed.
And of course, you need a running Gitlab instance.

Once you have the Project ID, you can set following configs in the terminal where you will be executing the
gcloud-commands. You can set the Region and zone to what ever you prefer.

```sh
export PROJECT_ID=YOUR-PROJECT_ID
gcloud config set project $PROJECT_ID
gcloud config set compute/region europe-west1
gcloud config set compute/zone europe-west1-c
```

Now we are ready to start deploying our setup.

This is the last command you need to run, everything else from this point forward will be automated.
Your Gitlab instances Runner Registration token can be found from the Admin Area -> Overview -> Runners.
export it to the environment:
```sh
create_runner.sh your_gcompute_instance_name $PROJECT_ID $GITLAB_REGISTERTAION_TOKEN $GIRLAB_URL $GCLOUD_SERVICEACCOUNT_EMANIl
```

And thats it, this process will take some time, so go ahead and grap a cup of coffee and you can check in your Gitlab Runners page,
when the cluster is ready.
Also you can of course monitor the progress manually by SSH:ing to the Runner controller machine and tailing the /var/log/syslog

```sh
gcloud --project $PROJECT_ID compute ssh your_gcompute_instance_name
```

## Unresolved

I still haven't found out why the Cache is not working properly, it might be the way the
Gitlab Runner currently handles Google Cloud Storage endpoint with the S3 compatibility mode.
I'll try to find time to fork the runner repository and rewrite the minion cache client to use the latest information
of how the GCS wants to handle the interoperability communication.

Also [tls can't be skipped according](http://moonlightbox.logdown.com/posts/2016/09/12/gitlab-ci-runner-register-x509-error)
So please follow this article.