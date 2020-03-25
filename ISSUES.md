# Known Issues:

## 1. PCL 1.8

* If you are experiencing the following error:
```commandline
/usr/include/pcl-1.8/pcl/impl/point_types.hpp:684:5: error: 'alignas' attribute only applies to variables, data members and tag types [clang-diagnostic-error]
  } EIGEN_ALIGN16;
    ^
```
This is a [known bug](https://github.com/PointCloudLibrary/pcl/blob/master/CHANGES.md#libpcl_2d) in PCL which was fixed in PR [#3237](https://github.com/PointCloudLibrary/pcl/pull/3237).

**Fixes:**
1. Either install `pcl>=v1.10.0`.
2. or hack the following change into `/usr/include/pcl-1.8/pcl/impl/point_types.hpp` directly by changing:
```c++
670: struct _PointXYZHSV
...
684: } EIGEN_ALIGN16;
```
to
```c++
670: struct EIGEN_ALIGN16 _PointXYZHSV
...
684: };
```

