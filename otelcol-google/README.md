# Custom OpenTelemetry Collector for Qoodish on Cloud Run

This directory contains the configuration to build a custom container image for the OpenTelemetry Collector. This image is deployed alongside the application on Google Cloud Run to collect and export telemetry data.

## Collector Distribution

We use the `otelopscol` distribution from Google Cloud's `opentelemetry-operations-collector` repository.

As noted in the official documentation, `otelopscol` is the OpenTelemetry Collector that backs the Google Cloud Ops Agent. It is specifically tooled for exporting telemetry data to Google Cloud's operations suite.

While it is officially supported by Google only as a component of the Ops Agent, it is suitable for our use case of building a standalone collector container.

## Purpose in this Project

The primary goal is to run the OpenTelemetry Collector as a sidecar container in our Cloud Run service. This collector receives OTLP metrics from the main application container and forwards them to Google Cloud Managed Service for Prometheus.

This directory contains a custom `collector-config.yaml` to configure the collector's behavior. We build a container image that includes this configuration and push it to Google Cloud's Artifact Registry.

## Reference

For more detailed information about the `otelopscol` distribution, please refer to the official repository:
https://github.com/GoogleCloudPlatform/opentelemetry-operations-collector
