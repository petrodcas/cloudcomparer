# cloudcomparer

Powershell7 utility to compare and filter cloud services

___

This script is intended to be used as a tool to assist on studying cloud certifications.

It can compare different cloud services, filtering by categories and services. Also, it is possible to get the equivalent solutions
in other platforms given an initial one.

As an example, this call would output the equivalent solutions for "amazon simple storage service (s3)" in other platforms.

```powershell7
.\Compare-CloudServices.ps1 -Solution 'Amazon Simple Storage Service (S3)' -FindEquivalent
```

**Output:**

```powershell7
Platform              Solution
--------              --------
Microsoft Azure       Azure Blob Storage
IBM Cloud             Cloud Object Storage
Google Cloud Platform Cloud Storage
Alibaba Cloud         Object Storage Service
Huawei Cloud          Object Storage Service
Oracle Cloud          Oracle Cloud Infrastructure Object Storage
```

## Customized csv

The given csv can be customized, for example, by editing the description to useful personal hints.

The given version has the links to the solutions as a default.

The included python script (*scrapper.py*) can scrap data from [comparecloud.in](**https://comparecloud.in/**) and generate an initial csv.

## Remark

Everything is configured so *Compare-CloudServices.ps1* searches for the csv in the same path and with the name ***clouds.csv***.
