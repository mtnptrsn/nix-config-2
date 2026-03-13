{ pkgs, ... }:

{
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  # Noise cancellation via RNNoise smart filter on RODE NT-USB mic
  environment.sessionVariables.LADSPA_PATH = "${pkgs.rnnoise-plugin}/lib/ladspa";
  services.pipewire.extraConfig.pipewire."99-input-denoising" = {
    "context.modules" = [
      {
        name = "libpipewire-module-filter-chain";
        args = {
          "node.description" = "Noise Canceling Source";
          "media.name" = "Noise Canceling Source";
          "filter.graph" = {
            nodes = [
              {
                type = "ladspa";
                name = "rnnoise";
                plugin = "librnnoise_ladspa";
                label = "noise_suppressor_mono";
                control = {
                  "VAD Threshold (%)" = 50.0;
                };
              }
            ];
          };
          "capture.props" = {
            "node.name" = "capture.rnnoise_source";
            "node.passive" = true;
            "audio.rate" = 48000;
            "audio.position" = [ "MONO" ];
          };
          "playback.props" = {
            "node.name" = "rnnoise_source";
            "media.class" = "Audio/Source";
            "audio.rate" = 48000;
            "filter.smart" = true;
            "filter.smart.name" = "rnnoise";
            "filter.smart.target" = {
              "node.name" = "alsa_input.usb-RODE_Microphones_RODE_NT-USB-00.analog-stereo";
            };
          };
        };
      }
    ];
  };
}
