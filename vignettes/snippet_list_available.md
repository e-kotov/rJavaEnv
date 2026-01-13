
### **List Available Java Versions**

To check which Java versions are available for download and installation, use:

```r
java_list_available()
```

You can also list versions provided by different backends (e.g., SDKMAN) or for other platforms:

```r
# List versions from SDKMAN
java_list_available(backend = "sdkman")

# List versions for all platforms (use with caution)
java_list_available(platform = "all", arch = "all")
```
