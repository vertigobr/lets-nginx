Carina
=====

Carina is an awesome service from Rackspace, still in beta for free (at this moment). It serves you a CaaS (Container as a Service) environment where you are free from the hassle of dealing with an entire VM just to deploy containers in clusters.

Yes, I am a big fan.

## Sign up

Go to [getcarina.com](getcarina.com), sign up to the beta and create your first cluster. Write down these settings:

* Your login
* Your API key (check at the top-right menu)
* Your cluster name

## Setup tools

Follow Carina instructions to install a few useful tools:

* [DVM - Docker Version Manager](https://getcarina.com/docs/tutorials/docker-version-manager/), a script to switch the docker client in your PATH;
* [Carina CLI](https://getcarina.com/docs/getting-started/getting-started-carina-cli/), a command-line utility to manage your Carina clusters.

## Settings

Have a "setenv.sh" script for fast-food configuring your prompt, something like:

```bash
export CARINA_USERNAME=your_carina_login
export CARINA_APIKEY=your_api_key
eval $(carina env your_cluster_name)
dvm use
```

To test connectivity with Carina you can list your clusters or "ps" a cluster:

```bash
carina list
docker ps
```

