
# Table of Contents

1.  [****1. Physical Inspection****](#orgd30e3c0)
2.  [****2. Network Traffic Monitoring****](#orgf10d7b6)
3.  [****3. Switch and Router Security****](#org3db3249)
4.  [****4. RF and EM Signal Detection****](#org96dc906)
5.  [****5. Endpoint and Server Logs****](#org0674dbf)



<a id="orgd30e3c0"></a>

# ****1. Physical Inspection****

Since hardware taps are physical devices, start by checking network infrastructure:

-   Look for ****unusual or unauthorized devices**** attached to network cables.
-   Inspect ****network closets, cable junctions, and patch panels**** for inserted taps or extra devices.
-   Use ****port security cameras**** in sensitive areas to monitor access.


<a id="orgf10d7b6"></a>

# ****2. Network Traffic Monitoring****

-   ****Port Mirroring & SPAN Analysis****:
    -   If a tap is duplicating network traffic, monitor for unexplained mirrored traffic.
-   ****Unusual Latency & Packet Drops****:
    -   Some passive taps may introduce slight delays. Compare expected vs. actual latency.
-   ****MAC Address Anomalies****:
    -   Look for unexpected MAC addresses appearing on switch ports.
-   ****Unusual ARP or DNS Requests****:
    -   Rogue devices may conduct MITM attacks using ARP spoofing.
-   ****NetFlow/SFlow Analysis****:
    -   Check for unexpected traffic leaving the network.


<a id="org3db3249"></a>

# ****3. Switch and Router Security****

-   ****Enable Port Security & BPDU Guard****:
    -   Helps detect unauthorized devices connecting to switches.
-   ****802.1X Authentication****:
    -   Prevents unauthorized devices from joining the network.
-   ****MAC Address Locking****:
    -   Binds a port to a specific MAC, preventing rogue devices.


<a id="org96dc906"></a>

# ****4. RF and EM Signal Detection****

-   ****RF Spectrum Analysis****:
    -   Some taps have wireless exfiltration. Use tools like Fluke Networks’ AirCheck or Wireshark with Wi-Fi adapters.
-   ****Tempest Shielding Considerations****:
    -   High-security environments may use electromagnetic shielding to prevent passive eavesdropping.


<a id="org0674dbf"></a>

# ****5. Endpoint and Server Logs****

-   ****Check for Unexpected Packet Captures****:
    -   On endpoints, look for processes using \`tcpdump\`, \`Wireshark\`, or \`WinPcap\`.
-   ****Monitor Network Adapter Activity****:
    -   Unexpected promiscuous mode settings (\`ifconfig eth0 promisc\` on Linux).

Would you like suggestions for tools to automate detection?

