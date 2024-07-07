
# Car Hacking 101

On the day of the release of this article, I was present at [incognito.kr](https://incognito.kr),
to talk about Automotive Cybersecurity, and how to get started in this field.

It should be noted that I am **not** an expert is this field by any means, I just have some experience
that I would like to share, and hopefully inspire other security-minded engineers to look into this
field, because it is interesting for many reasons. I was mainly coming in with a lot of software experience,
which has downsides & upsides, we will talk about that.

> You can find the slides of this talk [here](https://github.com/bogdzn/car_hacking_101_slides) !

Ready ? Let's get started.


## Brief overview of the Automotive Cybersecurity landscape

The main thing that is crucial to understand is that the Automotive Industry is mechanical, and works at _massive_
scales. To beat your competitor, it is not enough to have the better product, you must also be able to
deliver it reliably in volumes of 10s of thousands. You also have tight deadlines, and very strict requirements,
because this is a very competitive field.

Another thing to understand is that, although security in cars is [not new](https://jalopnik.com/the-first-car-alarm-was-sort-of-like-a-puzzle-471797268),
Cybersecurity is. It sort of came to a shock to industry that their cars were insecure when, in 2015, a Jeep Cherokee was [hacked](https://www.wired.com/2015/07/hackers-remotely-kill-jeep-highway/)
just to demonstrate how vulnerable cars can be. The two people doing this had everything, remotely. They could
turn the wheel, jerk the seatbelt, control the infotainment system. This kind of served as a baseline for the
nightmare scenario a car manufacturer can go through. Of course, Chrystler [patched](https://media.stellantisnorthamerica.com/newsrelease.do?&id=16827&mid=1)
the issue very quick, but they did not support OTA (Over The Air) firmware updates, so you had to upload manually, or at your
dealership to be safe from the exploit.

There were [other exploits](https://www.nytimes.com/2011/03/10/business/10hack.html) before that (one infamous case demonstrated a [police car](https://cacm.acm.org/magazines/2011/11/138210-hacking-cars/abstract) being hacked.).
However, this event served as a catalyst, because not only could you see the exploit, but you could also see the reaction of the
journalist, absolutely terrified because he realizes that he has _no control_ over his car, in the middle of the highway.
Nobody wants to be in this situation. Unlike most other cases of hacking, it can actually kill someone in this case.

In response, the carmakers have tried to adapt, with pentesting being a much more common practice, sometimes required by countries
to certify that cars can be used on the roads. However, it seems that not [every player is going at the same speed](https://rollingpwn.github.io/rolling-pwn/).

What we have seen in the car industry for the last ten years, is two nebulas colliding, the challenges of running a mechanical industry at scale, and those
of building secure software. As a researcher / attacker / threat actor, this is obviously something to consider when starting
to learn about car security.

## Attack surfaces

From all the attacks I've linked before, you may have noticed that the entrypoint is almost always different. As you can guess, a car has a _very large_
attack surface. I've often heard that "_a car is basically a computer on wheels_", but it's not exact in my mind. To me, a car is a _network on wheels_.
So, it's worse. :^)

The main attack surfaces (from my experience) are the following:
* The infotainment system: Often supports Bluetooth, WiFi and has a lot of user interaction
* [Mobile apps for car management](https://www.darkreading.com/application-security/siriusxm-myhyundai-car-apps-showcase-next-gen-car-hacking): They can interact directly with the car, while being in an environment that is easier to debug
* The [TPMS](https://www.bridgestonetire.com/learn/maintenance/tire-pressure-monitoring-system-how-tpms-works/) will send information regarding the pressure of your tires to the rest of the car, wirelessly. We will see later why that information can be spoofed.
* OTA (Over the air) / PCB Reverse-engineering: Some cars be updated wirelessly. This is interesting to us, because if we are able to conduct an MITM attack, we _could_ install our own firmware.
* Good old [API Hacking](https://samcurry.net/web-hackers-vs-the-auto-industry/)


Of course, there are other methods, like performing replay attacks, or
just [breaking the car's body](https://www.linkedin.com/feed/update/urn:li:activity:7015326958855028736/) to access the car's internal wiring underneath.

### The Controller Area Network

CAN is a protocol often referred to as the CAN bus. It was created by Bosch in 1986, and is still used to this day in medical devices and Automotive ECUs.
The layout of a CAN _frame_ is not complicated, but there is a lot of information you don't need to get started, so here is a oversimplified version:

```
          1 1 1 1 1 1
  0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5
 +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
 | Arbitration  | Control | Data  |
 |     ID      |  Field  | Field |
 +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
 |                                 |
 |            Data (0-8 bytes)     |
 |                                 |
 +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
 |       CRC       |   ACK   | EoF |
 +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
```

Later, the protocol was extended to support longer messages in the `data` field (up to 64bytes):
```
          1 1 1 1 1 1
  0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5
 +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
 | Arbitration  |  Control|   DLC |
 |     ID      |   Bits  |       |
 +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
 |                                 |
 |           Data (0-64 bytes)     |
 |                                 |
 +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
 |           CRC (16 bits)        |
 +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
```

In both cases, the frame starts with the arbitration ID field, which is used to identify the message and to determine its priority on the bus.
The control field contains information about the message type and format, while the data field contains the actual message payload.
In the classic CAN frame, the data field can contain up to 8 bytes of data, while in the CAN-FD frame, the data field can contain up to 64 bytes of data.
The length of the data field is indicated by the DLC field in the CAN-FD frame.
Both frames end with a cyclic redundancy check (CRC) field, which is used to detect errors in the message transmission,
as well as an acknowledgement (ACK) field in the classic CAN frame, and an end-of-frame (EoF) field in the CAN-FD frame.

Attentive readers will notice something weird about this. Indeed, the CAN is meant to run on a bus, and the sender of the message determines
the order of importance of the message sent, through the `arbitration ID` field. However, there is no check or verification to check if the
message is indeed as urgent as it seems.

This means that, if you are connected to the CAN bus with a rogue device, you can essentially block the car ECUs from receiving new messages if
you spam the bus with messages with a super low arbitration ID, kind of like this:

```python
#!/bin/python3

import can

bus = can.Bus()
while True:
    msg = can.Message(12, data=[0 for _ in range(8)])
    bus.send(msg)
```

If ECUs don't receive updates of the other ECUs, they will assume they are faulty, and turn on a [DTC](https://www.clearpathgps.com/blog/what-are-dtc-codes).
In some cases, they can even shut down, provided they are not critical for the safety of the passengers.

As you can see, this flaw is quite easy to exploit, and not trivial to defend against. The reason for this, is that the vulnerability comes from a
design flaw, not a failure to implement something properly. Of course, the Internet was barely a thing in 1986, and it's not fair to expect from
Bosch engineers to imagine a future where cars could be connected wirelessly to the internal CAN bus. And even if it was the case, they probably
assumed the protocol would change.

There has been at least one attempt to use another protocol that I'm aware of: [FlexRay](https://en.wikipedia.org/wiki/FlexRay#Sampled_bits), but AFAIK it is not used outside of BMW vehicles.

Recently, automakers have been attemtping to implement [SecOC](https://autosec.se/wp-content/uploads/2019/03/4.-Bashar-Dawood.pdf), aka `Secure On-Board Communications`.
However, implementing this and making the transition is not trivial for automakers, because the supply chain has to be in sync, since they all have to use the same standard.
OEMs will often ask for other industrial companies to build ECUs for them, or car parts, which will then be assembled by the constructor in the end.
Also, SecOC is not a silver bullet, it does not prevent a rogue actor from listening on the network, because the messages are only signed. (If you haven't clicked on the link, you
really should, it's an excellent resource for understanding SecOC.)

> another thing worth mentioning here is [AutoSAR](https://arxiv.org/pdf/2109.00099.pdf), the underlying architecture on which ECUs run on.
> However, you will not see it a lot on the offensive side, so maybe don't spend to much time on it.

### Dataframes and protocols

As you can see from the nice ascii arts above, each CAN frame send a blob of data. This data is often referred to as a `Message`.
Often, constructors will all have different messages, which are stored in a CAN database.
You can find some reverse-engineered databases [here](https://github.com/commaai/opendbc) in the [dbc](https://github.com/stefanhoelzl/CANpy) format.
There are other formats for specifiying CAN databases, depending on the software used by constructors, but it will often be `dbc` from my experience.

Getting a hold of this database is the first thing you want once you get access to a CAN bus, because it allows you to know which message you can send,
and interact with the car. There are many tools you can use to do fuzzing, and figure out how to make the car do stuff. It really depends on your needs.

There are also some standardized messages, but they're typically protected by Authentication mechanism, such as [XCP](https://en.wikipedia.org/wiki/XCP_(protocol)) (a debugging and
calibration protocol), and [UDS](https://en.wikipedia.org/wiki/Unified_Diagnostic_Services) (aka `Unified Diagnostic Services`).

Both of them work with a `seed/key` algorithm, for which the implementation depends on the constructor. Depending on your target, you can find
[other researchers' work](https://github.com/ludwig-v/psa-seedkey-algorithm) to get access to these messages, and change calibrations, perform binary dumps, etc.

A more detailed description of the UDS protocol is available [here](https://uds.readthedocs.io/en/latest/pages/knowledge_base/diagnostic_message.html).

### Connecting to a car

So you have two types of tools to be wired to a car: The really nice (enterprise-level) ones, and the more DIY ones (which are actually quite nice).
For the enterprise-level stuff, forget it, it's so expansive that you have to _call_ the company to know the price, and even if you manage to find
one on ebay, you will have to pay a (hefty) license fee to use the software that is meant to be used with such hardware.

That leaves you with the _DIY_-ish stuff, eg: [ODB-II](https://en.wikipedia.org/wiki/On-board_diagnostics) connectors. Fortunately, you can find an OBD-II port on almost any car, under the wheel and to the right.
Pretty much any of them work, provided your car doesn't use some proprietary CAN derivative.

If you don't have a car and want to experiment with the CAN protocol, you don't even need a car to get started -- just Linux. (Think about it, the software
stack for the infotainment system often runs on Linux, so there is support out of the box):
```bash
# enable kernel module
#
# if you you use a can connector, you can just retract the v from vcan
# in the following commands
sudo modprobe vcan

# set up the network interface
# s/vcan/can if using a real connector
sudo ip link add dev vcan0 type vcan

# run the interface
sudo ip link set up vcan0
```

Then, you will have a working CAN interface, that is even able to generate random messages for you if you need it to.
This is helpful for development, though AFAIK it cannot respect `.dbc`/`.REF` specifications. (yet)

After doing this, i would advise you to use the `python-can` package, and it's all you need to get started basically!

### Useful links & write-ups

Here are compiled, in no particular order, other ressources that ive used when learning about cars:
* [fault injection on renesas rh580](https://blog.willemmelching.nl/carhacking/2022/11/08/rh850-glitch/)
* [0-click RCE Tesla Model 3 -- presentation](https://www.youtube.com/watch?v=k_F4wHc4h6k)
* [srecords specs](http://srecord.sourceforge.net/man/man5/srec_motorola.html ) -> often used for car firmware dumps
* [Paper on Car Fuzzing using Vector software](https://pure.coventry.ac.uk/ws/portalfiles/portal/37979533/Fowler_PhD.pdf)
* [Another Tesla hack write-up](https://keenlab.tencent.com/en/2020/01/02/exploiting-wifi-stack-on-tesla-model-s/)

If the interest is here for another article, i might do it but it feels like a lot of information already, and i don't want to make it too long, so please let me
know if you are curious on this subject.
