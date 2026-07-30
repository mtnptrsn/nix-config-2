_: {
  services.tailscale = {
    enable = true;
    useRoutingFeatures = "client";
    # Tailscale SSH, applied by tailscaled-set.service.
    # extraUpFlags would be ignored since there is no authKeyFile (login is interactive).
    extraSetFlags = [ "--ssh" ];
  };
}
