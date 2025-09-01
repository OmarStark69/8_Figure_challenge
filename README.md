# 8_Figure_challenge

### Part 1: Data Ingestion

#### Workflow Description

1.  **Manual Trigger (`Execute workflow`):** For testing purposes, a manual trigger is used to start the workflow, but a scheduled trigger could be used instead, checking for changes in the file, or new files in a specific Drive folder.
2.  **Download (`Download file`):** Retrieves the `ads_spend.csv` file directly from the provided Google Drive URL.
3.  **Extraction (`Extract From File`):** Processes the downloaded file, extracting the data from the CSV format so it can be manipulated in the following steps.
4.  **Field Editing (`Edit Fields`):** Adds the origin file name, to know the origin of every row in the DB.
5.  **Duplicate Removal (`Remove Duplicates`):** In case the same file is used and only new rows are added, this node keeps a memory of previously read data, avoiding to deliver duplicate data to following nodes in workflow, therefore avoiding inserting duplicates in the SQL table.
6.  **Row Creation (`Create a row`):** Inserts the clean into the target table in the data warehouse, I used Supabase because setup is easy for testing.

#### Setup


1.  **Import Workflow:** Import the workflow's JSON file into n8n canvas.
2.  **Configure Credentials:** The final node (`Create a row`) requires credentials to connect to the target database (e.g., Supabase, BigQuery, etc.)[cite: 11]. Edit the node and add your own credentials to establish the connection.
3.  **Verify URL:** The `Download file` node contains the docment ID from Google Drive for the dataset. Ensure it is right.

### Part 2: KPI Modeling with SQL

The query calculates the following Key Performance Indicators (KPIs):
* **CAC (Customer Acquisition Cost):** Calculated as `spend / conversions`.
* **ROAS (Return On Ad Spend):** Calculated as `(revenue / spend)`, with revenue defined as `conversions × 100`.

#### Key Features

The SQL model includes several key features to ensure an accurate and resilient analysis:

* **Date Ranging:** The last queried date is used as input, getting the date ranges from the previous 30 days, and the 30 days before that
* **Comparative Analysis:** The output is a compact table that directly compares the performance of the two periods, showing the absolute values for each KPI side-by-side. 
* **Delta Calculation:** The final table includes a `delta_percent` column, which calculates the percentage change between the prior and current periods for each metric.
* **Error Prevention:** The calculations use `NULLIF` to prevent division-by-zero errors, which could occur if a period had zero conversions or spend.

#### Usage

The `*.sql` script is included in this repository. It can be run in any SQL client connected to the populated data warehouse (e.g., Supabase SQL Editor) to generate the final comparison table.

### Part 3: Analyst Access via API

An n8n workflow was created to serve as the API. This workflow is triggered by an HTTP request and returns the query results in JSON format.

The workflow consists of three key nodes:

1.  **Webhook Node:** This node generates a unique URL that acts as the public endpoint. It listens for incoming `GET` requests and captures URL parameters like `start` and `end`.
2.  **Postgres Node:** Upon being triggered, this node connects to the database and executes a parameterized SQL query. The query is designed to dynamically inject the `start` and `end` dates from the webhook into its `WHERE` clause, ensuring the calculation is performed only on the requested date range.
3.  **Respond to Webhook Node:** This final node takes the data returned by the Postgres query and sends it back to the client as the HTTP response, formatted as a JSON object.

#### API Usage

The user specifies the desired period by providing `start` and `end` dates as URL query parameters.

  * **Endpoint:** `/metrics?start=<YYYY-MM-DD>&end=<YYYY-MM-DD>`
  * **Example Call:**
    ```
    https://<your-n8n-url>/webhook/metrics?start=2022-03-01&end=2022-03-15
    ```
  * **Example JSON Output:**
    ```json
    [
      {
        "cac": 14.88,
        "roas": 6.72,
        "total_spend": 5410.5,
        "total_conversions": 363
      }
    ]
    ```
The only required setup is to connect the Postgres node to the data warehouse, in this case, the connection was made with the already existing Supabase table through the credentials provided in the project>Connect section, under 'Transaction pooler'.

### Part 4: AI Agent Implementation (Bonus)

Instead of a theoretical mapping, this project implements a functional, AI-powered agent using n8n and the Google Gemini language model. This agent can understand natural language questions from a chat interface, interpret the user's intent, and execute the correct SQL query to provide an answer.

#### Workflow Architecture

1.  **Chat Trigger (`When chat message received`):** The workflow initiates when a new message is received, allowing for real-time, interactive data analysis.

2.  **AI Core (`AI Extract dates`):** At the heart of the agent is an AI node powered by **Google's Gemini Chat Model**. This node takes the message and transforms it to two possible outputs depending on the user prompt:
   * If only one date is mentioned, then a formatted date YYYY-MM-DD is delivered, meaning that the two previous months up to that date are being compared, regarding their KPIs
   * If one start date and one end date are mentioned, two formatted dates YYYY-MM-DD are delivered, meaning that the KPIs for that specified period will be queried.

3.  **Conditional Routing (`If` node):** Based on the structured output from the AI, an `If` node acts as a router. It checks if the user provided a specific date range.
    * If **`true`**, the workflow proceeds to a query designed for custom time periods.
    * If **`false`**, it defaults to the standard comparative analysis query.

5.  **Dynamic Query Execution (`Postgres` nodes):**
    * **KPIs in a specific period:** This branch executes the parameterized SQL query that calculates KPIs for a specific `start` and `end` date provided by the user.
    * **KPI from current and prev:** This branch executes the comparative SQL query, providing the "last 30 days vs. prior 30 days" analysis.

To make this workflow run, two credentials have to be added:
    1. **Gemini Model:** API key from Google Cloud Console.
    2. **Postgres: ** connection with Supabase (or preferred data warehouse) table.
