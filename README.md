Graph database of 8,431 open-source Android apps
================================================

This Docker image contains an installation of [Neo4j](https://neo4j.com) with a dataset of 8,431 open-source Android apps, Google Play page data, and version control data in one graph database.

Snapshots of all GitHub repositories are cloned to a local Gitlab instance in a separate container (see below).


## Background and motivation

The idea is to create a dataset of open-source Android applications which can serve as a base for research. Data on Android apps is spread out over multiple source and finding a large number real-world applications with access to source code requires combining these different databases.


## Installation

Data is split into two parts:

 * Neo4j graph database which contains metadata as described in Section _Graph database content_.
 * Gitlab instance with snapshots of all Git repositories in the dataset.

For either image to run [Docker needs to be installed.](https://docs.docker.com/install/)

### Graph database: Neo4j

The Docker image containing the graph database is based on the [official Neo4j image.](https://store.docker.com/images/neo4j)  The only difference is, that this Docker image contains the dataset and an [`EXTENSION_SCRIPT`](http://neo4j.com/docs/operations-manual/current/installation/docker/#docker-new-image) ([`load_db.sh`](https://github.com/af60f75b/neo4j_open_source_android_apps/blob/master/scripts/load_db.sh)) which preloads the data when starting the container.

 1. Pull this image: `docker pull af60f75b/neo4j_open_source_android_apps`
 2. Use it as decribed in [official documentation](http://neo4j.com/docs/operations-manual/current/installation/docker/)

For example:

    docker run --rm --detach=true \
        --publish=7474:7474 --publish=7687:7687 \
        af60f75b/neo4j_open_source_android_apps

This command starts the Docker image and exposes ports used by Neo4j. The `--rm` options tells Docker to remove any newly created data inside the container after it has stopped running.

Map volumes into the container in order to persist state between executions:

    docker run --rm --detach=true \
        --publish=7474:7474 --publish=7687:7687 \
        --volume=$HOME/neo4j/data:/data \
        --volume=$HOME/neo4j/logs:/logs \
        af60f75b/neo4j_open_source_android_apps


When running the container for the first time, data gets imported into the graph database. This can take several seconds. Subsequent starts with an existing database in a mapped volume skip the importing step.


### Git repositories: Gitlab

The image containing Git repositories is [built from a fork](https://github.com/af60f75b/gitlab_open_source_android_apps/blob/gitlab_open_source_android_apps/docker/Dockerfile) of the [official Gitlab Docker image.](https://store.docker.com/images/gitlab-enterprise-edition) The main difference is, that instead of in a mountable volume, all Git repositories in out dataset are manually persisted in the image.

With almost 150GB in size the image containing clones of all Git repositories in the dataset exceeds size limits of Docker Hub and needs to be downloaded and loaded manually:

 1. [Download the image (tar archive, 145GB)](https://www.dropbox.com/s/e9ld70s72mxc85y/docker_gitlab_open_source_android_apps.tar.gz?dl=0)
 2. Load the image into Docker: `docker load -i path/to/docker_gitlab_open_source_android_apps.tar.gz`
 3. Use the image as described in the [official documentation.](https://docs.gitlab.com/omnibus/docker/README.html).

 For instance:

```
    docker run --rm --detach=true \
        --publish 80:80 --publish 2222:22 \
        --hostname=145.108.225.21 \
        gitlab_open_source_android_apps
```

The web interface is available at port 80 after Gitlab has started up, which may take several minutes. Log-in is possible with user `root` and password `gitlab`. Git repositories can be cloned from port `2222`.


## Usage

You can access the Neo4j web-interface at `http://localhost:7474` and connect _Gopher_ clients to `bolt://localhost:7687`.

Alternatively, a  _Cypher_ shell can be run with the `bin/cypher-shell` command once a container is running.  Use the container ID returned by the `docker run` command or find it out with `docker ps`.

    $ docker run <...>  # As above
    6455917a2532b0c9bc335f93568022bd66c6dd4208f16b29b7f8b14b9418238b
    $ docker exec --interactive --tty 6455917a2532b0c9bc335f93568022bd66c6dd4208f16b29b7f8b14b9418238b bin/cypher-shell

When logging in for the first time, a new password needs to be set. Log-in with username `neo4j` and password `neo4j` to set a new password. [This step can be skipped by setting a default password or disabling authentication.](http://neo4j.com/docs/operations-manual/current/installation/docker/#docker-overview).


![Neo4j Web Interface](https://github.com/af60f75b/neo4j_open_source_android_apps/raw/master/doc/img/neo4jwebinterface.png)


## Graph database content

The results of the data collection process are a list of 8,431 open-source Android apps with metadata from their Google Play pages and 8,216 GitHub repositories with the source code of those apps.

All this information is made available in two ways:

 1. A Neo4j graph database containing metadata of repositories and apps and highlevel information on commit history of all repositories.
 2. Snapshots of all GitHub repositories in the dataset cloned to a local Gitlab instance.

![Schema of the graph database](https://github.com/af60f75b/neo4j_open_source_android_apps/raw/master/doc/img/dbstructure.png)

All properties of node `GooglePlayPage`
--------------------------------------

Property                   |Type             |Description
---------------------------|-----------------|---------------------------------------------------------------------------------------
docId                      |String           |Identifier of an app, `com.example.app`. This property is always present.
uri                        |String           |The URI of the Google Play page.
snapshotTimestamp          |Long             |POSIX timestamp when metadata from the Google Play entry was stored.
title                      |String           |Title of the app listing.
appCategory                |List of Strings  |A list of categories such as “Tools”.
promotionalDescription     |String           |Short description of the app.
descriptionHtml            |String           |Description of the app in original language.
translatedDescriptionHtml  |String           |Translation of `descriptionHtml` if available.
versionCode                |Int              |Numeric value of the version of the app.
versionString              |String           |Human readable version string.
uploadDate                 |Long             |POSIX timestamp of latest update of app.
formattedAmount            |String           |Price of app (“Free” or “\$1.66”)
currencyCode               |String           |Three character currency code of price (“USD”)
in-app purchases           |String           |Description of in-app purchases (“\$3.19 per item”)
installNotes               |String           |Either “Contains ads” or no value.
starRating                 |Float            |Average review between 0 and 5. May not be available if too few users have rated yet.
numDownloads               |String           |Estimated number of downloads as displayed on Google Play (e.g “10,000+ downloads”).
developerName              |String           |Name of developer.
developerEmail             |String           |Email address of developer.
developerWebsite           |String           |URI of website.
targetSdkVersion           |Int              |Android SDK version the app targets.
permissions                |List of Strings  |List of permission identifiers.

All properties of node `GitHubRepository`
----------------------------------------

Property           |Type    |Description
-------------------|--------|---------------------------------------------------------------------------------------------------------------------------------------------------------------------------
id                 |Long    |Numerical identifier of this repository on GitHub.
owner              |String  |Owner name at snapshot time.
name               |String  |Repository name at snapshot time.
snapshot           |String  |URI to clone of the repository.
snapshotTimestamp  |Long    |POSIX timestamp when snapshot was taken.
description        |String  |Short description of the repository.
createdAt          |Long    |POSIX timestamp when repository has been created.
forksCount         |Int     |Number of forks from this repository created with GitHub’s *fork* functionality. Other ways of forking, cloning locally and pushing to a new repostitory are not counted.
stargazersCount    |Int     |Number of GitHub users having starred this repository.
subscribersCount   |Int     |Number of GitHub subscribers.
watchersCount      |Int     |Number of users watching this repository.
networkCount       |Int     |Number of repositories forked from same source.
ownerType          |String  |Account type of the owner, either “User” or “Organization”.
parentId           |Long    |Id of parent repository if this is a fork, otherwise -1.
sourceId           |Long    |Id of ancestor repository if this is a fork, otherwise -1.


## Example Queries

For some of these queries, the Neo4j plugin [APOC](https://guides.neo4j.com/apoc) is necessary. Install it by mapping it into the container as follows:

    $ mkdir plugins
    $ cd plugins
    $ wget https://github.com/neo4j-contrib/neo4j-apoc-procedures/releases/download/3.3.0.1/apoc-3.3.0.1-all.jar
    $ docker run --rm --detach=true \
        --publish=7474:7474 --publish=7687:7687 \
        --volume=$PWD:/plugins \
        af60f75b/neo4j_open_source_android_apps

### Example 1

Select apps belonging to the _Finance_ category with more than 10 commits in a given week.

    WITH apoc.date.parse('2017-01-01', 's', 'yyyy-MM-dd')
            as start,
        apoc.date.parse('2017-01-08', 's', 'yyyy-MM-dd')
            as end
    MATCH (p:GooglePlayPage)<-[:PUBLISHED_AT]-
        (a:App)-[:IMPLEMENTED_BY]->
        (:GitHubRepository)<-[:BELONGS_TO]-
        (:Commit)<-[c:COMMITS]-(:Contributor)
    WHERE 'Finance' in p.appCategory
        AND start <= c.timestamp < end
    WITH a.id as package, SIZE(COLLECT(DISTINCT c)) as commitCount
    WHERE commitCount > 10
    RETURN package, commitCount

### Example 2

Select contributors who worked on more than one app in a given month.

    WITH apoc.date.parse('2017-01-01', 's', 'yyyy-MM-dd')
            as start,
        apoc.date.parse('2017-08-01', 's', 'yyyy-MM-dd')
            as end
    MATCH (app1:App)-[:IMPLEMENTED_BY]->
        (:GitHubRepository)<-[:BELONGS_TO]-
        (:Commit)<-[c1:COMMITS|AUTHORS]-
        (c:Contributor)-[c2:COMMITS|AUTHORS]->
        (:Commit)-[:BELONGS_TO]->
        (:GitHubRepository)<-[:IMPLEMENTED_BY]-
        (app2:App)
    WHERE c.email <> 'noreply@github.com'
        AND app1.id <> app2.id
        AND start <= c1.timestamp < end
        AND start <= c2.timestamp < end
    RETURN DISTINCT c
    LIMIT 20

### Example 3

Providing our dataset in containerized form allows future research to easily augment the data and combine it for new insights. The following is a very simple example showcasing this possibility.  Assuming all commits have been tagged with self-reported activity of developers, select all commits in which the developer is fixing a performance-related bug.  For demonstration purposes, a very simple tagger is applied. Optimally, tagging is done with a more sophisticated model.

    MATCH (c:Commit)
    WHERE c.message CONTAINS 'performance'
    SET c :PerformanceFix

Also, given these additional labels, performance related fixes can then be easily used in any kind of query via the following snippet.

    MATCH (c:Commit:PerformanceFix) RETURN c LIMIT 20

### Example 4

Metadata from GitHub and Google Play can be combined and compared.  Both platforms have popularity measures such as star ratings.  The following query returns these metrics for further analysis.

    MATCH (r:GitHubRepository)<-[:IMPLEMENTED_BY]-
        (a:App)-[:PUBLISHED_AT]->(p:GooglePlayPage)
    RETURN a.id, p.starRating, r.forksCount,
        r.stargazersCount, r.subscribersCount,
        r.watchersCount, r.networkCount
    LIMIT 20

### Example 5

Does a higher number of contributors relates to more successful apps? The following query returns the average review rating on Google Play and the number of contributors to the source code.

    MATCH (c:Contributor)-[:AUTHORS|COMMITS]->
        (:Commit)-[:BELONGS_TO]->
        (:GitHubRepository)<-[:IMPLEMENTED_BY]-
        (a:App)-[:PUBLISHED_AT]->(p:GooglePlayPage)
    WITH p.starRating as rating, a.id as package,
        SIZE(COLLECT(DISTINCT c)) as contribCount
    RETURN package, rating, contribCount
    LIMIT 20
