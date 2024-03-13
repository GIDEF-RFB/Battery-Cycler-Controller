# CSIC Cycler

This repository contains four different Python packages for Cycler project.

## Battery Cyclers CU Manager

[This module provides the classes and methods to manage the computational unit. It configures the external communication to receive and send message using mqtt driver, it can detect connected devices and publish them into the mqtt broker and it also manage the cycler station deployment inside the CU.]

## Battery Cycler Controler

[This module provides the classes and methods to manage the main devices that will control the cycler station, with parallel threading to manage measurements, storage and power control.]

## Battery Cycler Datatypes

[This module provides the classes and methods with all the datatypes needed in the main packages in order to have a homogeneus
and common types among the packages.]

## Battery Cycler DB Sync

[This module provides the classes and methods to synchronice the local data storaged in a cache database and insert it in the master database.]
