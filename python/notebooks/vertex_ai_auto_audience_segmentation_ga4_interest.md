# Automated Audience Segmentation Approach 

## Challenges
*   We don’t know ahead of time how many segments (clusters) will be useful to keep going
    * With k-means clustering you have to specify k ahead of training
    * With hierarchical clustering, you don’t have to specify the number of clusters, but at some point, you have to draw a threshold line that will determine the number of segments
*   Once you have the segments, you have to give them business names
    * Hard to do programmatically
    * Likely a need for human intervention
*   Segments need to be explainable
    * Need to have meaningful business value
    * The customer needs to understand them
    * Segmentation can be done on many things and many attributes
        * Throwing all possible attributes into segmentation makes them very hard to explain nicely
        * A small number of focus attributes helps explainability, but you are leaving a lot out
        * Interest vs. engagement segmentation
*   A retrain might generate a new set of segments
    * Confusing for the customer


## Solutions
#### We don’t know ahead of time how many segments (clusters) will be helpful to keep going
*   Running k-means within a hyperparameter framework
    * Hyper-params
        *  `k` (number of clusters)
        * Optional: 
            * Different strategies to normalize the data
            * Adding and removing columns
            * Different levels of outlier removal
    * Optimization metrics
        * [Silhouette Score](https://scikit-learn.org/stable/auto_examples/cluster/plot_kmeans_silhouette_analysis.html)  ** *our preferred method*
        * [Sum of Square Distance](https://www.google.com/books/edition/Application_of_Intelligent_Systems_in_Mu/j5YqEAAAQBAJ?hl=en&gbpv=1&dq=SSM+sum+of+square+distance+kmeans&pg=PA228&printsec=frontcover) (SSM)
        * [Davies–Bouldin index](https://en.wikipedia.org/wiki/Davies%E2%80%93Bouldin_index)
        * General rule: prefer smaller `k`, this helps with explainability
*   Possible hybrid solution:
    * Run hyper-optimization for `k`, and optimize silhouette score
    * From all trials, note the score of the best trial
    * Pick a trial that has a silhouette score within `x%` of the best silhouette score but has the lowest `k` of those within `x%`

#### Once you have the segments, you have to give them business names
*    Segments could be pushed for activation as in S1, S2, and S3,...but there should be some sort of dashboard that explains what each number means, what attributes are considered
     * Business names, in this case, would be done after the fact within the dashboard after a human would apply business knowledge review the dashboard and add notes)
    
#### Segments need to be explainable
*    The easiest way to make them explainable is to reduce the number of attributes to something below 10 (there are exceptions, of course)
*    You can only reduce the number of attributes if you know your clusters' aim, as you can always cluster by many different attributes, so picking a direction you want your clusters to go is critical. Some examples:
     * Interest in the site
     * Engagement on the site
     * Geo attributes
     * Sales funnel stage
*    The typical starter segmentation is using page paths (and possibly events) to cluster by site engagement or site interest
     * Site engagement would heavily rely on the frequency of visits to particular page paths, with added global attributes like the number of sessions, recency, and time between sessions,...
     * Site interest would rely heavily on page paths, but instead of frequency, we would need to infer interest from each visitor.
         * Example: There are three possible URLs: A, B, C
             * Visitor 1: A: 1, B: 4, C: 8
             * Visitor 2: A: 0, B:1, C: 2
             * Engagement-wise, those two visitors are very different, but interest-wise, they should fall into the same segment.
         * We can use TF-IDF to normalize the vectors and pretend that page URLs are words and each vector is a document. Then normalize all vectors to the length of 1.
             * This removes all frequency information, and the above two examples should have very similar vectors
         * Likely, one could create a query that extracts the page level 1 path and creates a dataset for clustering based on the interest and invariant of the customer. Similarly, for engagement, it should be even easier to grab engagement-level metrics (sessions, pageviews, time on site, recency,...) independent of the customer
*    Ideally, a dashboard should be generated where cluster exploration is possible and where you can compare clusters head to head to see where the centroids differ

#### A retrain might generate a new set of segments
*    This could be solved in two ways
     * A) Use the same random seed when retraining 
     * B) Use the previous centroids as your initial centroids in the retrain
*    BQML doesn’t support setting random seeds, [so the best option is to just use previous centroids as the init centroids for the retrain](https://cloud.google.com/bigquery/docs/reference/standard-sql/bigqueryml-syntax-create-kmeans#kmeans_init_method)
     * This ensures that even with some new data, the centroids will not end up being too different from what they were before, which means the business names can likely be kept as well












