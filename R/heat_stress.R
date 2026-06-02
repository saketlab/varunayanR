#' heat stress index calculations
#'
#' @name heat_stress
NULL

#' Calculate relative humidity from temperature and dewpoint
#'
#' Uses the Magnus-Tetens approximation to calculate relative humidity
#' from air temperature and dewpoint temperature.
#'
#' @param temp_c Air temperature in celsius
#' @param dewpoint_c Dewpoint temperature in celsius
#' @return Relative humidity as percentage (0-100)
#' @export
#' @examples
#' relative_humidity_from_dewpoint(25, 18)
relative_humidity_from_dewpoint <- function(temp_c, dewpoint_c) {
  a <- 17.625
  b <- 243.04

  gamma_t <- (a * temp_c) / (b + temp_c)
  gamma_td <- (a * dewpoint_c) / (b + dewpoint_c)

  rh <- 100 * exp(gamma_td - gamma_t)
  pmin(pmax(rh, 0), 100)
}

#' Calculate wet bulb temperature
#'
#' Calculates wet bulb temperature using the Stull (2011) empirical formula.
#' Valid for temperatures between -20C and 50C and RH between 5% and 99%.
#'
#' @param temp_c Air temperature in celsius
#' @param rh Relative humidity as percentage (0-100)
#' @return Wet bulb temperature in Celsius
#' @references Stull, R. (2011). Wet-Bulb Temperature from Relative Humidity
#'   and Air Temperature. Journal of Applied Meteorology and Climatology,
#'   50(11), 2267-2269. https://journals.ametsoc.org/view/journals/apme/50/11/jamc-d-11-0143.1.xml
#' @export
#' @examples
#' wet_bulb_temperature(30, 60)
wet_bulb_temperature <- function(temp_c, rh) {
  # Clamp to Stull's stated validity window (RH 5-99%) to avoid extrapolation.
  rh <- pmin(pmax(rh, 5), 99)
  temp_c * atan(0.151977 * sqrt(rh + 8.313659)) +
    atan(temp_c + rh) -
    atan(rh - 1.676331) +
    0.00391838 * (rh^1.5) * atan(0.023101 * rh) -
    4.686035
}

#' Calculate wet bulb temperature from dewpoint
#'
#' @param temp_c Air temperature in celsius
#' @param dewpoint_c Dewpoint temperature in celsius
#' @return Wet bulb temperature in celsius
#' @export
#' @examples
#' wet_bulb_from_dewpoint(30, 22)
wet_bulb_from_dewpoint <- function(temp_c, dewpoint_c) {
  rh <- relative_humidity_from_dewpoint(temp_c, dewpoint_c)
  wet_bulb_temperature(temp_c, rh)
}

#' Calculate heat index (apparent temperature)
#'
#'
#' @param temp_c Air temperature in celsius
#' @param rh Relative humidity as percentage (0-100)
#' @return Heat index in celsius
#' @references Rothfusz, L.P. (1990). The Heat Index Equation.
#'   NWS Southern Region Technical Attachment, SR/SSD 90-23.
#'   https://www.weather.gov/media/ffc/ta_htindx.PDF
#' @export
#' @examples
#' heat_index(35, 70)
heat_index <- function(temp_c, rh) {
  temp_f <- temp_c * 9 / 5 + 32
  hi_f <- ifelse(
    temp_f < 80,
    0.5 * (temp_f + 61.0 + (temp_f - 68.0) * 1.2 + rh * 0.094),
    {
      hi <- -42.379 +
        2.04901523 * temp_f +
        10.14333127 * rh -
        0.22475541 * temp_f * rh -
        0.00683783 * temp_f^2 -
        0.05481717 * rh^2 +
        0.00122874 * temp_f^2 * rh +
        0.00085282 * temp_f * rh^2 -
        0.00000199 * temp_f^2 * rh^2

      adj <- ifelse(
        rh < 13 & temp_f >= 80 & temp_f <= 112,
        -((13 - rh) / 4) * sqrt((17 - abs(temp_f - 95)) / 17),
        ifelse(
          rh > 85 & temp_f >= 80 & temp_f <= 87,
          ((rh - 85) / 10) * ((87 - temp_f) / 5),
          0
        )
      )

      hi + adj
    }
  )

  (hi_f - 32) * 5 / 9
}

#' Calculate heat index from dewpoint
#'
#' @param temp_c Air temperature in celsius
#' @param dewpoint_c Dewpoint temperature in celsius
#' @return Heat index in celsius
#' @export
#' @examples
#' heat_index_from_dewpoint(35, 25)
heat_index_from_dewpoint <- function(temp_c, dewpoint_c) {
  rh <- relative_humidity_from_dewpoint(temp_c, dewpoint_c)
  heat_index(temp_c, rh)
}

#' Calculate WBGT (Wet Bulb Globe Temperature)
#'
#' Calculates the Australian Bureau of Meteorology closed-form WBGT
#' approximation (Steadman-based) from air temperature and dewpoint. Suitable
#' for occupational heat stress assessment when only temperature and humidity
#' are available.
#'
#' @param temp_c Air temperature in Celsius
#' @param dewpoint_c Dewpoint temperature in Celsius
#' @return WBGT in Celsius
#' @references
#'   Liljegren, J.C., et al. (2008). Modeling the Wet Bulb Globe Temperature
#'   Using Standard Meteorological Measurements. J. Occup. Environ. Hyg., 5(10), 645-655.
#'   Methods for Estimating Wet Bulb Globe Temperature
# From Remote and Low-Cost Data: A Comparative Study in Central Alabama Anabel W. Carter, Benjamin F. Zaitchik , Julia M. Gohlke, Suwei Wang , and
# Molly B. Richardson  https://vtechworks.lib.vt.edu/server/api/core/bitstreams/b482c33c-ca60-4ece-a99f-f2b36cef3eeb/content
#' @export
#' @examples
#' wbgt_simple(35, 25)
wbgt_simple <- function(temp_c, dewpoint_c) {
  # Australian Bureau of Meteorology closed-form WBGT approximation
  # (Steadman-based): requires only air temperature and humidity, fully
  # reproducible. e = vapor pressure in hPa.
  e <- vapor_pressure_from_dewpoint(dewpoint_c)
  0.567 * temp_c + 0.393 * e + 3.94
}

#' Calculate shade/indoor Wet Bulb Globe Temperature (ISO 7243)
#'
#' Uses the indoor formula 0.7*Tw + 0.3*Ta. For a closed-form estimate from
#' temperature and humidity alone, use \code{wbgt_simple()}.
#'
#' @param temp_c Air temperature in Celsius
#' @param wet_bulb_c Wet bulb temperature in Celsius
#' @return WBGT in Celsius
#' @export
#' @examples
#' wbgt_shade(35, 27)
wbgt_shade <- function(temp_c, wet_bulb_c) {
  0.7 * wet_bulb_c + 0.3 * temp_c
}

#' Calculate WBGT from dewpoint
#'
#' Alias for \code{wbgt_simple()} (BoM closed-form WBGT from temperature and
#' dewpoint).
#'
#' @param temp_c Air temperature in celsius
#' @param dewpoint_c Dewpoint temperature in celsius
#' @return WBGT in Celsius
#' @export
#' @examples
#' wbgt_from_dewpoint(35, 25)
wbgt_from_dewpoint <- function(temp_c, dewpoint_c) {
  wbgt_simple(temp_c, dewpoint_c)
}

#' Calculate humidex (Canadian heat index)
#'
#' @param temp_c Air temperature in celsius
#' @param dewpoint_c Dewpoint temperature in celsius
#' @return Humidex in celsius
#' @references Masterson, J. & Richardson, F.A. (1979). Humidex, A Method of
#'   Quantifying Human Discomfort Due to Excessive Heat and Humidity.
#'   Environment Canada, Atmospheric Environment Service.
#' @export
#' @examples
#' humidex(30, 22)
humidex <- function(temp_c, dewpoint_c) {
  e <- 6.11 * exp(5417.7530 * (1 / 273.16 - 1 / (273.15 + dewpoint_c)))
  temp_c + 0.5555 * (e - 10)
}

#' Calculate vapor pressure from dewpoint temperature
#'
#' @param dewpoint_c Dewpoint temperature in celsius
#' @return Vapor pressure in hPa (hectopascals)
#' @export
#' @examples
#' vapor_pressure_from_dewpoint(20)
vapor_pressure_from_dewpoint <- function(dewpoint_c) {
  6.112 * exp(17.67 * dewpoint_c / (dewpoint_c + 243.5))
}

#' Estimate mean radiant temperature
#'
#' Estimates mean radiant temperature (Tmrt) from meteorological variables.
#' Uses simplified approach when full radiation data unavailable.
#'
#' @param temp_c Air temperature in Celsius
#' @param solar_radiation Solar radiation in W/m2 (optional)
#' @param wind_speed Wind speed in m/s (optional)
#' @return Mean radiant temperature in Celsius
#' @export
#' @examples
#' mean_radiant_temperature(30, solar_radiation = 800, wind_speed = 2)
mean_radiant_temperature <- function(temp_c, solar_radiation = NULL, wind_speed = NULL) {
  if (is.null(solar_radiation)) {
    return(temp_c)
  }
  # Closed-form radiation-balance estimator for a standard person
  # (Thorsson et al. 2007): absorb global horizontal shortwave onto the
  # longwave radiant balance. Deterministic and non-iterative; wind_speed is
  # unused (wind enters the convective terms of UTCI/WBGT, not the radiant load).
  sigma <- 5.670374419e-8 # Stefan-Boltzmann, W m^-2 K^-4 (CODATA 2018)
  eps_p <- 0.97 # longwave emissivity of a standard person
  a_k <- 0.7 # shortwave absorption coefficient of a standard person
  fa <- 0.25 # rotationally-averaged projected area factor
  ta_k <- temp_c + 273.15
  ((ta_k^4) + (a_k * fa * solar_radiation) / (eps_p * sigma))^0.25 - 273.15
}

# Saturation vapor pressure (kPa) using the UTCI reference es() routine
# (Broede 2012 operational code). Shared by utci() for cross-language parity.
.utci_saturation_kpa <- function(temp_c) {
  g <- c(
    -2836.5744, -6028.076559, 19.54263612, -0.02737830188,
    0.000016261698, 7.0229056e-10, -1.8680009e-13
  )
  tk <- temp_c + 273.15
  es <- 2.7150305 * log(tk)
  for (i in seq_along(g)) {
    es <- es + g[i] * tk^(i - 3)
  }
  # exp(es) is in Pa; the UTCI polynomial expects vapor pressure in kPa.
  exp(es) * 0.001
}

#' Calculate UTCI (Universal Thermal Climate Index)
#'
#' Calculates UTCI using the polynomial approximation from Bröde et al. (2012),
#' based on a multi-node model of human thermoregulation.
#'
#' @param temp_c Air temperature in Celsius (-50 to 50)
#' @param wind_speed Wind speed at 10m height in m/s (0.5 to 17)
#' @param dewpoint_c Dewpoint temperature in Celsius (to calculate vapor pressure)
#' @param tmrt Mean radiant temperature in Celsius (optional, defaults to temp_c)
#' @return UTCI in Celsius
#' @references Bröde, P., et al. (2012). Deriving the operational procedure for
#'   the Universal Thermal Climate Index (UTCI). International Journal of
#'   Biometeorology, 56(3), 481-494.
#' @export
#' @examples
#' utci(30, wind_speed = 2, dewpoint_c = 20)
#' utci(35, wind_speed = 1, dewpoint_c = 25, tmrt = 45)
utci <- function(temp_c, wind_speed, dewpoint_c, tmrt = NULL) {
  Ta <- temp_c
  va <- pmax(pmin(wind_speed, 17), 0.5)
  # Water-vapor pressure in kPa via the UTCI reference saturation routine,
  # scaled by relative humidity. Matches the Python implementation exactly.
  rh <- relative_humidity_from_dewpoint(temp_c, dewpoint_c)
  Pa <- (rh / 100) * .utci_saturation_kpa(temp_c)
  # Broede (2012) is defined for delta-MRT in [-30, 70] K.
  D_Tmrt <- if (is.null(tmrt)) 0 else pmin(pmax(tmrt - temp_c, -30), 70)

  utci_val <- Ta +
    0.607562052 +
    (-0.0227712343) * Ta +
    (8.06470249e-4) * Ta * Ta +
    (-1.54271372e-4) * Ta * Ta * Ta +
    (-3.24651735e-6) * Ta * Ta * Ta * Ta +
    (7.32602852e-8) * Ta * Ta * Ta * Ta * Ta +
    (1.35959073e-9) * Ta * Ta * Ta * Ta * Ta * Ta +
    (-2.25836520) * va +
    (0.0880326035) * Ta * va +
    (0.00216844454) * Ta * Ta * va +
    (-1.53347087e-5) * Ta * Ta * Ta * va +
    (-5.72983704e-7) * Ta * Ta * Ta * Ta * va +
    (-2.55090145e-9) * Ta * Ta * Ta * Ta * Ta * va +
    (-0.751269505) * va * va +
    (-0.00408350271) * Ta * va * va +
    (-5.21670675e-5) * Ta * Ta * va * va +
    (1.94544667e-6) * Ta * Ta * Ta * va * va +
    (1.14099531e-8) * Ta * Ta * Ta * Ta * va * va +
    (0.158137256) * va * va * va +
    (-6.57263143e-5) * Ta * va * va * va +
    (2.22697524e-7) * Ta * Ta * va * va * va +
    (-4.16117031e-8) * Ta * Ta * Ta * va * va * va +
    (-0.0127762753) * va * va * va * va +
    (9.66891875e-6) * Ta * va * va * va * va +
    (2.52785852e-9) * Ta * Ta * va * va * va * va +
    (4.56306672e-4) * va * va * va * va * va +
    (-1.74202546e-7) * Ta * va * va * va * va * va +
    (-5.91491269e-6) * va * va * va * va * va * va +
    (0.398374029) * D_Tmrt +
    (1.83945314e-4) * Ta * D_Tmrt +
    (-1.73754510e-4) * Ta * Ta * D_Tmrt +
    (-7.60781159e-7) * Ta * Ta * Ta * D_Tmrt +
    (3.77830287e-8) * Ta * Ta * Ta * Ta * D_Tmrt +
    (5.43079673e-10) * Ta * Ta * Ta * Ta * Ta * D_Tmrt +
    (-0.0200518269) * va * D_Tmrt +
    (8.92859837e-4) * Ta * va * D_Tmrt +
    (3.45433048e-6) * Ta * Ta * va * D_Tmrt +
    (-3.77925774e-7) * Ta * Ta * Ta * va * D_Tmrt +
    (-1.69699377e-9) * Ta * Ta * Ta * Ta * va * D_Tmrt +
    (1.69992415e-4) * va * va * D_Tmrt +
    (-4.99204314e-5) * Ta * va * va * D_Tmrt +
    (2.47417178e-7) * Ta * Ta * va * va * D_Tmrt +
    (1.07596466e-8) * Ta * Ta * Ta * va * va * D_Tmrt +
    (8.49242932e-5) * va * va * va * D_Tmrt +
    (1.35191328e-6) * Ta * va * va * va * D_Tmrt +
    (-6.21531254e-9) * Ta * Ta * va * va * va * D_Tmrt +
    (-4.99410301e-6) * va * va * va * va * D_Tmrt +
    (-1.89489258e-8) * Ta * va * va * va * va * D_Tmrt +
    (8.15300114e-8) * va * va * va * va * va * D_Tmrt +
    (7.55043090e-4) * D_Tmrt * D_Tmrt +
    (-5.65095215e-5) * Ta * D_Tmrt * D_Tmrt +
    (-4.52166564e-7) * Ta * Ta * D_Tmrt * D_Tmrt +
    (2.46688878e-8) * Ta * Ta * Ta * D_Tmrt * D_Tmrt +
    (2.42674348e-10) * Ta * Ta * Ta * Ta * D_Tmrt * D_Tmrt +
    (1.54547250e-4) * va * D_Tmrt * D_Tmrt +
    (5.24110970e-6) * Ta * va * D_Tmrt * D_Tmrt +
    (-8.75874982e-8) * Ta * Ta * va * D_Tmrt * D_Tmrt +
    (-1.50743064e-9) * Ta * Ta * Ta * va * D_Tmrt * D_Tmrt +
    (-1.56236307e-5) * va * va * D_Tmrt * D_Tmrt +
    (-1.33895614e-7) * Ta * va * va * D_Tmrt * D_Tmrt +
    (2.49709824e-9) * Ta * Ta * va * va * D_Tmrt * D_Tmrt +
    (6.51711721e-7) * va * va * va * D_Tmrt * D_Tmrt +
    (1.94960053e-9) * Ta * va * va * va * D_Tmrt * D_Tmrt +
    (-1.00361113e-8) * va * va * va * va * D_Tmrt * D_Tmrt +
    (-1.21206673e-5) * D_Tmrt * D_Tmrt * D_Tmrt +
    (-2.18203660e-7) * Ta * D_Tmrt * D_Tmrt * D_Tmrt +
    (7.51269482e-9) * Ta * Ta * D_Tmrt * D_Tmrt * D_Tmrt +
    (9.79063848e-11) * Ta * Ta * Ta * D_Tmrt * D_Tmrt * D_Tmrt +
    (1.25006734e-6) * va * D_Tmrt * D_Tmrt * D_Tmrt +
    (-1.81584736e-9) * Ta * va * D_Tmrt * D_Tmrt * D_Tmrt +
    (-3.52197671e-10) * Ta * Ta * va * D_Tmrt * D_Tmrt * D_Tmrt +
    (-3.36514630e-8) * va * va * D_Tmrt * D_Tmrt * D_Tmrt +
    (1.35908359e-10) * Ta * va * va * D_Tmrt * D_Tmrt * D_Tmrt +
    (4.17032620e-10) * va * va * va * D_Tmrt * D_Tmrt * D_Tmrt +
    (-1.30369025e-9) * D_Tmrt * D_Tmrt * D_Tmrt * D_Tmrt +
    (4.13908461e-10) * Ta * D_Tmrt * D_Tmrt * D_Tmrt * D_Tmrt +
    (9.22652254e-12) * Ta * Ta * D_Tmrt * D_Tmrt * D_Tmrt * D_Tmrt +
    (-5.08220384e-9) * va * D_Tmrt * D_Tmrt * D_Tmrt * D_Tmrt +
    (-2.24730961e-11) * Ta * va * D_Tmrt * D_Tmrt * D_Tmrt * D_Tmrt +
    (1.17139133e-10) * va * va * D_Tmrt * D_Tmrt * D_Tmrt * D_Tmrt +
    (6.62154879e-10) * D_Tmrt * D_Tmrt * D_Tmrt * D_Tmrt * D_Tmrt +
    (4.03863260e-13) * Ta * D_Tmrt * D_Tmrt * D_Tmrt * D_Tmrt * D_Tmrt +
    (1.95087203e-12) * va * D_Tmrt * D_Tmrt * D_Tmrt * D_Tmrt * D_Tmrt +
    (-4.73602469e-12) * D_Tmrt * D_Tmrt * D_Tmrt * D_Tmrt * D_Tmrt * D_Tmrt +
    (5.12733497) * Pa +
    (-0.312788561) * Ta * Pa +
    (-0.0196701861) * Ta * Ta * Pa +
    (9.99690870e-4) * Ta * Ta * Ta * Pa +
    (9.51738512e-6) * Ta * Ta * Ta * Ta * Pa +
    (-4.66426341e-7) * Ta * Ta * Ta * Ta * Ta * Pa +
    (0.548050612) * va * Pa +
    (-0.00330552823) * Ta * va * Pa +
    (-0.00164119440) * Ta * Ta * va * Pa +
    (-5.16670694e-6) * Ta * Ta * Ta * va * Pa +
    (9.52692432e-7) * Ta * Ta * Ta * Ta * va * Pa +
    (-0.0429223622) * va * va * Pa +
    (0.00500845667) * Ta * va * va * Pa +
    (1.00601257e-6) * Ta * Ta * va * va * Pa +
    (-1.81748644e-6) * Ta * Ta * Ta * va * va * Pa +
    (-1.25813502e-3) * va * va * va * Pa +
    (-1.79330391e-4) * Ta * va * va * va * Pa +
    (2.34994441e-6) * Ta * Ta * va * va * va * Pa +
    (1.29735808e-4) * va * va * va * va * Pa +
    (1.29064870e-6) * Ta * va * va * va * va * Pa +
    (-2.28558686e-6) * va * va * va * va * va * Pa +
    (-0.0369476348) * D_Tmrt * Pa +
    (0.00162325322) * Ta * D_Tmrt * Pa +
    (-3.14279680e-5) * Ta * Ta * D_Tmrt * Pa +
    (2.59835559e-6) * Ta * Ta * Ta * D_Tmrt * Pa +
    (-4.77136523e-8) * Ta * Ta * Ta * Ta * D_Tmrt * Pa +
    (8.64203390e-3) * va * D_Tmrt * Pa +
    (-6.87405181e-4) * Ta * va * D_Tmrt * Pa +
    (-9.13863872e-6) * Ta * Ta * va * D_Tmrt * Pa +
    (5.15916806e-7) * Ta * Ta * Ta * va * D_Tmrt * Pa +
    (-3.59217476e-5) * va * va * D_Tmrt * Pa +
    (3.28696511e-5) * Ta * va * va * D_Tmrt * Pa +
    (-7.10542454e-7) * Ta * Ta * va * va * D_Tmrt * Pa +
    (-1.24382300e-5) * va * va * va * D_Tmrt * Pa +
    (-7.38584400e-9) * Ta * va * va * va * D_Tmrt * Pa +
    (2.20609296e-7) * va * va * va * va * D_Tmrt * Pa +
    (-7.32469180e-4) * D_Tmrt * D_Tmrt * Pa +
    (-1.87381964e-5) * Ta * D_Tmrt * D_Tmrt * Pa +
    (4.80925239e-6) * Ta * Ta * D_Tmrt * D_Tmrt * Pa +
    (-8.75492040e-8) * Ta * Ta * Ta * D_Tmrt * D_Tmrt * Pa +
    (2.77862930e-5) * va * D_Tmrt * D_Tmrt * Pa +
    (-5.06004592e-6) * Ta * va * D_Tmrt * D_Tmrt * Pa +
    (1.14325367e-7) * Ta * Ta * va * D_Tmrt * D_Tmrt * Pa +
    (2.53016723e-6) * va * va * D_Tmrt * D_Tmrt * Pa +
    (-1.72857035e-8) * Ta * va * va * D_Tmrt * D_Tmrt * Pa +
    (-3.95079398e-8) * va * va * va * D_Tmrt * D_Tmrt * Pa +
    (-3.59413173e-7) * D_Tmrt * D_Tmrt * D_Tmrt * Pa +
    (7.04388046e-7) * Ta * D_Tmrt * D_Tmrt * D_Tmrt * Pa +
    (-1.89309167e-8) * Ta * Ta * D_Tmrt * D_Tmrt * D_Tmrt * Pa +
    (-4.79768731e-7) * va * D_Tmrt * D_Tmrt * D_Tmrt * Pa +
    (7.96079978e-9) * Ta * va * D_Tmrt * D_Tmrt * D_Tmrt * Pa +
    (1.62897058e-9) * va * va * D_Tmrt * D_Tmrt * D_Tmrt * Pa +
    (3.94367674e-8) * D_Tmrt * D_Tmrt * D_Tmrt * D_Tmrt * Pa +
    (-1.18566247e-9) * Ta * D_Tmrt * D_Tmrt * D_Tmrt * D_Tmrt * Pa +
    (3.34678041e-10) * va * D_Tmrt * D_Tmrt * D_Tmrt * D_Tmrt * Pa +
    (-1.15606447e-10) * D_Tmrt * D_Tmrt * D_Tmrt * D_Tmrt * D_Tmrt * Pa +
    (-2.80626406) * Pa * Pa +
    (0.548712484) * Ta * Pa * Pa +
    (-0.00399428410) * Ta * Ta * Pa * Pa +
    (-9.54009191e-4) * Ta * Ta * Ta * Pa * Pa +
    (1.93090978e-5) * Ta * Ta * Ta * Ta * Pa * Pa +
    (-0.308806365) * va * Pa * Pa +
    (0.0116952364) * Ta * va * Pa * Pa +
    (4.95271903e-4) * Ta * Ta * va * Pa * Pa +
    (-1.90710882e-5) * Ta * Ta * Ta * va * Pa * Pa +
    (0.00210787756) * va * va * Pa * Pa +
    (-6.98445738e-4) * Ta * va * va * Pa * Pa +
    (2.30109073e-5) * Ta * Ta * va * va * Pa * Pa +
    (4.17856590e-4) * va * va * va * Pa * Pa +
    (-1.27043871e-5) * Ta * va * va * va * Pa * Pa +
    (-3.04620472e-6) * va * va * va * va * Pa * Pa +
    (0.0514507424) * D_Tmrt * Pa * Pa +
    (-0.00432510997) * Ta * D_Tmrt * Pa * Pa +
    (8.99281156e-5) * Ta * Ta * D_Tmrt * Pa * Pa +
    (-7.14663943e-7) * Ta * Ta * Ta * D_Tmrt * Pa * Pa +
    (-2.66016305e-4) * va * D_Tmrt * Pa * Pa +
    (2.63789586e-4) * Ta * va * D_Tmrt * Pa * Pa +
    (-7.01199003e-6) * Ta * Ta * va * D_Tmrt * Pa * Pa +
    (-1.06823306e-4) * va * va * D_Tmrt * Pa * Pa +
    (3.61341136e-6) * Ta * va * va * D_Tmrt * Pa * Pa +
    (2.29748967e-7) * va * va * va * D_Tmrt * Pa * Pa +
    (3.04788893e-4) * D_Tmrt * D_Tmrt * Pa * Pa +
    (-6.42070836e-5) * Ta * D_Tmrt * D_Tmrt * Pa * Pa +
    (1.16257971e-6) * Ta * Ta * D_Tmrt * D_Tmrt * Pa * Pa +
    (7.68023384e-6) * va * D_Tmrt * D_Tmrt * Pa * Pa +
    (-5.47446896e-7) * Ta * va * D_Tmrt * D_Tmrt * Pa * Pa +
    (-3.59937910e-8) * va * va * D_Tmrt * D_Tmrt * Pa * Pa +
    (-4.36497725e-6) * D_Tmrt * D_Tmrt * D_Tmrt * Pa * Pa +
    (1.68737969e-7) * Ta * D_Tmrt * D_Tmrt * D_Tmrt * Pa * Pa +
    (2.67489271e-8) * va * D_Tmrt * D_Tmrt * D_Tmrt * Pa * Pa +
    (3.23926897e-9) * D_Tmrt * D_Tmrt * D_Tmrt * D_Tmrt * Pa * Pa +
    (-0.0353874123) * Pa * Pa * Pa +
    (-0.221201190) * Ta * Pa * Pa * Pa +
    (0.0155126038) * Ta * Ta * Pa * Pa * Pa +
    (-2.63917279e-4) * Ta * Ta * Ta * Pa * Pa * Pa +
    (0.0453433455) * va * Pa * Pa * Pa +
    (-0.00432943862) * Ta * va * Pa * Pa * Pa +
    (1.45389826e-4) * Ta * Ta * va * Pa * Pa * Pa +
    (2.17508610e-4) * va * va * Pa * Pa * Pa +
    (-6.66724702e-5) * Ta * va * va * Pa * Pa * Pa +
    (3.33217140e-5) * va * va * va * Pa * Pa * Pa +
    (-0.00226921615) * D_Tmrt * Pa * Pa * Pa +
    (3.80261982e-4) * Ta * D_Tmrt * Pa * Pa * Pa +
    (-5.45314314e-9) * Ta * Ta * D_Tmrt * Pa * Pa * Pa +
    (-7.96355448e-4) * va * D_Tmrt * Pa * Pa * Pa +
    (2.53458034e-5) * Ta * va * D_Tmrt * Pa * Pa * Pa +
    (-6.31223658e-6) * va * va * D_Tmrt * Pa * Pa * Pa +
    (3.02122035e-4) * D_Tmrt * D_Tmrt * Pa * Pa * Pa +
    (-4.77403547e-6) * Ta * D_Tmrt * D_Tmrt * Pa * Pa * Pa +
    (1.73825715e-6) * va * D_Tmrt * D_Tmrt * Pa * Pa * Pa +
    (-4.09087898e-7) * D_Tmrt * D_Tmrt * D_Tmrt * Pa * Pa * Pa +
    (0.614155345) * Pa * Pa * Pa * Pa +
    (-0.0616755931) * Ta * Pa * Pa * Pa * Pa +
    (0.00133374846) * Ta * Ta * Pa * Pa * Pa * Pa +
    (0.00355375387) * va * Pa * Pa * Pa * Pa +
    (-5.13027851e-4) * Ta * va * Pa * Pa * Pa * Pa +
    (1.02449757e-4) * va * va * Pa * Pa * Pa * Pa +
    (-0.00148526421) * D_Tmrt * Pa * Pa * Pa * Pa +
    (-4.11469183e-5) * Ta * D_Tmrt * Pa * Pa * Pa * Pa +
    (-6.80434415e-6) * va * D_Tmrt * Pa * Pa * Pa * Pa +
    (-9.77675906e-6) * D_Tmrt * D_Tmrt * Pa * Pa * Pa * Pa +
    (0.0882773108) * Pa * Pa * Pa * Pa * Pa +
    (-0.00301859306) * Ta * Pa * Pa * Pa * Pa * Pa +
    (0.00104452989) * va * Pa * Pa * Pa * Pa * Pa +
    (2.47090539e-4) * D_Tmrt * Pa * Pa * Pa * Pa * Pa +
    (0.00148348065) * Pa * Pa * Pa * Pa * Pa * Pa

  utci_val
}

#' Calculate UTCI using sparse regression approximation
#'
#' Calculates UTCI using the sparse regression approximation with Legendre
#' polynomials from Roman et al. (2025). This is a more accurate approximation
#' than the original Bröde et al. (2012) polynomial, with fewer terms and
#' better numerical stability.
#'
#' @param temp_c Air temperature in Celsius (-50 to 50)
#' @param tmrt Mean radiant temperature in Celsius
#' @param wind_speed Wind speed at 10m height in m/s (0.5 to 30.3)
#' @param rh Relative humidity as percentage (5 to 100)
#' @return UTCI in Celsius
#' @references Roman, S., Skok, G., Todorovski, L., & Dzeroski, S. (2025).
#'   UTCI approximation using sparse regression with orthogonal polynomials.
#'   Zenodo. https://doi.org/10.5281/zenodo.17465548 https://arxiv.org/abs/2508.11307
#' @export
#' @examples
#' utci_sparse(30, tmrt = 40, wind_speed = 2, rh = 60)
#' utci_sparse(35, tmrt = 35, wind_speed = 1, rh = 80)
utci_sparse <- function(temp_c, tmrt, wind_speed, rh) {
  Ta <- temp_c
  Tr <- tmrt
  va <- wind_speed

  va <- pmax(pmin(va, 30.3), 0.5)
  rh <- pmax(pmin(rh, 100), 5)

  dTrTa <- Tr - Ta

  nTa <- Ta / 50
  ndTrTa <- (dTrTa - 20) / 50
  nva <- (va - 15.4) / 14.9
  nrH <- (rh - 52.5) / 47.5

  Ta1 <- nTa
  Ta2 <- 0.5 * (-1 + 3 * nTa^2)
  Ta3 <- 0.5 * (-3 * nTa + 5 * nTa^3)
  Ta4 <- 0.125 * (3 - 30 * nTa^2 + 35 * nTa^4)
  Ta5 <- 0.125 * (15 * nTa - 70 * nTa^3 + 63 * nTa^5)
  Ta6 <- 0.0625 * (-5 + 105 * nTa^2 - 315 * nTa^4 + 231 * nTa^6)
  Ta7 <- 0.0625 * (-35 * nTa + 315 * nTa^3 - 693 * nTa^5 + 429 * nTa^7)
  Ta8 <- 0.0078125 * (35 - 1260 * nTa^2 + 6930 * nTa^4 - 12012 * nTa^6 + 6435 * nTa^8)
  Ta9 <- 0.0078125 * (315 * nTa - 4620 * nTa^3 + 18018 * nTa^5 - 25740 * nTa^7 + 12155 * nTa^9)
  Ta10 <- 0.00390625 * (-63 + 3465 * nTa^2 - 30030 * nTa^4 + 90090 * nTa^6 - 109395 * nTa^8 + 46189 * nTa^10)

  dTrTa1 <- ndTrTa
  dTrTa2 <- 0.5 * (-1 + 3 * ndTrTa^2)
  dTrTa3 <- 0.5 * (-3 * ndTrTa + 5 * ndTrTa^3)

  va1 <- nva
  va2 <- 0.5 * (-1 + 3 * nva^2)
  va3 <- 0.5 * (-3 * nva + 5 * nva^3)
  va4 <- 0.125 * (3 - 30 * nva^2 + 35 * nva^4)
  va5 <- 0.125 * (15 * nva - 70 * nva^3 + 63 * nva^5)
  va6 <- 0.0625 * (-5 + 105 * nva^2 - 315 * nva^4 + 231 * nva^6)
  va7 <- 0.0625 * (-35 * nva + 315 * nva^3 - 693 * nva^5 + 429 * nva^7)
  va8 <- 0.0078125 * (35 - 1260 * nva^2 + 6930 * nva^4 - 12012 * nva^6 + 6435 * nva^8)
  va9 <- 0.0078125 * (315 * nva - 4620 * nva^3 + 18018 * nva^5 - 25740 * nva^7 + 12155 * nva^9)
  va10 <- 0.00390625 * (-63 + 3465 * nva^2 - 30030 * nva^4 + 90090 * nva^6 - 109395 * nva^8 + 46189 * nva^10)

  rH1 <- nrH
  rH2 <- 0.5 * (-1 + 3 * nrH^2)
  rH3 <- 0.5 * (-3 * nrH + 5 * nrH^3)
  rH4 <- 0.125 * (3 - 30 * nrH^2 + 35 * nrH^4)
  rH5 <- 0.125 * (15 * nrH - 70 * nrH^3 + 63 * nrH^5)
  rH6 <- 0.0625 * (-5 + 105 * nrH^2 - 315 * nrH^4 + 231 * nrH^6)
  rH7 <- 0.0625 * (-35 * nrH + 315 * nrH^3 - 693 * nrH^5 + 429 * nrH^7)
  rH8 <- 0.0078125 * (35 - 1260 * nrH^2 + 6930 * nrH^4 - 12012 * nrH^6 + 6435 * nrH^8)
  rH9 <- 0.0078125 * (315 * nrH - 4620 * nrH^3 + 18018 * nrH^5 - 25740 * nrH^7 + 12155 * nrH^9)

  UTCI_offset_normalized <-
    -0.0137842169737312 +
    0.605451658287147 * Ta1 +
    0.228978616673604 * dTrTa1 +
    -0.411887517706717 * va1 +
    0.0516822161148559 * rH1 +
    0.280580929387293 * Ta2 +
    0.0494441100625763 * Ta1 * dTrTa1 +
    0.407606222800615 * Ta1 * va1 +
    0.0989531628394581 * Ta1 * rH1 +
    0.0246471408147623 * dTrTa2 +
    -0.0571289630222624 * dTrTa1 * va1 +
    -0.00981948141197167 * dTrTa1 * rH1 +
    0.115659720373134 * va2 +
    -0.00534228470468843 * va1 * rH1 +
    0.016606193686503 * rH2 +
    -0.151030966047951 * Ta2 * dTrTa1 +
    0.188807982337807 * Ta2 * va1 +
    0.0881449234650015 * Ta2 * rH1 +
    -0.00930063989106069 * Ta1 * dTrTa2 +
    0.0215873308746893 * Ta1 * dTrTa1 * va1 +
    -0.0227872935667395 * Ta1 * dTrTa1 * rH1 +
    -0.11306527433562 * Ta1 * va2 +
    -0.0109236071122277 * Ta1 * va1 * rH1 +
    0.0255963885144559 * Ta1 * rH2 +
    -0.000676664345791177 * dTrTa3 +
    0.0244340319236622 * dTrTa1 * va2 +
    0.0020488990800455 * dTrTa1 * va1 * rH1 +
    -0.00198787369921777 * dTrTa1 * rH2 +
    -0.0262531747919802 * va3 +
    0.00241202999394371 * va2 * rH1 +
    -0.0899003481633464 * Ta4 +
    -0.0518348124459142 * Ta3 * dTrTa1 +
    -0.019305242850497 * Ta3 * va1 +
    0.0288567768313003 * Ta3 * rH1 +
    -0.00532373584837672 * Ta2 * dTrTa2 +
    0.00865046786070809 * Ta2 * dTrTa1 * va1 +
    -0.0200025901337491 * Ta2 * dTrTa1 * rH1 +
    -0.0560921250768577 * Ta2 * va2 +
    -0.0120111532564824 * Ta2 * va1 * rH1 +
    0.0193526595005879 * Ta2 * rH2 +
    -0.00147617610703898 * Ta1 * dTrTa3 +
    0.0147709386142124 * Ta1 * dTrTa2 * va1 +
    0.000223025361668181 * Ta1 * dTrTa2 * rH1 +
    -0.0267126314476705 * Ta1 * dTrTa1 * va2 +
    0.00293284619228001 * Ta1 * dTrTa1 * va1 * rH1 +
    -0.00274343594032762 * Ta1 * dTrTa1 * rH2 +
    0.0255375758890182 * Ta1 * va3 +
    0.00617742875276631 * Ta1 * va2 * rH1 +
    0.00131758038812698 * dTrTa3 * va1 +
    -1.19588186117375e-05 * dTrTa2 * va2 +
    -0.0195473208292468 * dTrTa1 * va3 +
    0.0308499978887788 * va4 +
    -0.00168292560551294 * va3 * rH1 +
    -0.000721243580359172 * rH4 +
    0.0241135789170187 * Ta5 +
    0.0667693514821362 * Ta4 * dTrTa1 +
    -0.105442958374474 * Ta4 * va1 +
    0.0169733342570069 * Ta3 * dTrTa2 +
    -0.0588730143622148 * Ta3 * dTrTa1 * va1 +
    -0.00478455509424903 * Ta3 * dTrTa1 * rH1 +
    0.0322224934071458 * Ta3 * va2 +
    -0.0109309219781879 * Ta3 * va1 * rH1 +
    0.00298613871955914 * Ta2 * dTrTa3 +
    -0.00970592755419437 * Ta2 * dTrTa2 * va1 +
    0.0143009046314569 * Ta2 * va3 +
    0.0073472142860989 * Ta2 * va2 * rH1 +
    -0.0118859833533268 * Ta2 * rH3 +
    -0.00811197236365886 * Ta1 * dTrTa2 * va2 +
    0.0202049930797466 * Ta1 * dTrTa1 * va3 +
    -0.00948544475972315 * Ta1 * va4 +
    -0.00407327808659386 * Ta1 * va3 * rH1 +
    0.0013485215681372 * dTrTa2 * va3 +
    0.00386595947690624 * dTrTa1 * va4 +
    2.17696778130301e-05 * dTrTa1 * va3 * rH1 +
    -0.00261892113164038 * dTrTa1 * rH4 +
    -0.00489648267639115 * va5 +
    0.000681848728845763 * va4 * rH1 +
    0.0082368236806339 * Ta6 +
    0.0421952883373002 * Ta5 * dTrTa1 +
    -0.0188866947129327 * Ta5 * va1 +
    -0.0230895202091769 * Ta5 * rH1 +
    0.00050946740381826 * Ta4 * dTrTa2 +
    0.0387368190996963 * Ta4 * va2 +
    -0.00365652796668801 * Ta4 * va1 * rH1 +
    -0.0165226812597451 * Ta4 * rH2 +
    -0.02106808547032 * Ta3 * dTrTa2 * va1 +
    0.0455127356554093 * Ta3 * dTrTa1 * va2 +
    -0.0327523492050705 * Ta3 * va3 +
    0.00411199080502651 * Ta3 * va2 * rH1 +
    -0.00529398688982106 * Ta3 * rH3 +
    -0.00299659797672848 * Ta2 * dTrTa3 * va1 +
    0.0127070225168592 * Ta2 * dTrTa2 * va2 +
    -0.0039536575347961 * Ta2 * va3 * rH1 +
    0.00176928876312725 * Ta1 * dTrTa2 * va3 +
    0.0249223383434746 * Ta1 * va5 +
    0.0010279948173077 * Ta1 * va4 * rH1 +
    -0.000456624197665442 * dTrTa2 * va4 +
    0.000227993624070799 * dTrTa2 * rH4 +
    -0.000497222888028054 * dTrTa1 * va1 * rH4 +
    0.00189906855480326 * va2 * rH4 +
    -0.00516323105647903 * rH6 +
    -0.0388335821720079 * Ta7 +
    -0.0142074242411286 * Ta6 * dTrTa1 +
    0.0488685513521004 * Ta6 * va1 +
    -0.0269122930593438 * Ta6 * rH1 +
    -0.00845228865914141 * Ta5 * dTrTa2 +
    0.0386364103297441 * Ta5 * dTrTa1 * va1 +
    0.00333840546426587 * Ta5 * dTrTa1 * rH1 +
    -0.0274986339482448 * Ta5 * va2 +
    -0.0233728308709061 * Ta5 * rH2 +
    -0.0010233136301785 * Ta4 * dTrTa3 +
    0.0109665440679091 * Ta4 * dTrTa2 * va1 +
    -0.0141154511737893 * Ta4 * dTrTa1 * va2 +
    0.00797571345288548 * Ta4 * dTrTa1 * rH2 +
    -0.00626818826879268 * Ta4 * rH3 +
    0.000541492731933859 * Ta3 * dTrTa2 * va2 +
    -0.0194848041587283 * Ta3 * dTrTa1 * va3 +
    -0.00242146589114414 * Ta3 * dTrTa1 * va1 * rH2 +
    0.00862214501674155 * Ta3 * va4 +
    -0.000813086246676268 * Ta3 * va3 * rH1 +
    -0.0109313281200866 * Ta2 * dTrTa2 * va3 +
    0.0107908356351421 * Ta2 * dTrTa1 * va4 +
    -0.00154886246960825 * Ta2 * dTrTa1 * rH4 +
    0.000285510363654986 * Ta2 * va3 * rH2 +
    0.00600871455392313 * Ta1 * dTrTa1 * va5 +
    0.0133563698637056 * Ta1 * va6 +
    0.00200056613397992 * dTrTa2 * va5 +
    -0.000487892088628483 * dTrTa2 * va1 * rH4 +
    0.00239926457161527 * dTrTa1 * va2 * rH4 +
    -0.00147299336560724 * va3 * rH4 +
    -0.0034747543766636 * rH7 +
    -0.042138668585659 * Ta7 * dTrTa1 +
    0.0226809825649836 * Ta7 * va1 +
    -0.0317422118129167 * Ta7 * rH1 +
    -0.0165868569214051 * Ta6 * dTrTa2 +
    0.00866283641928592 * Ta6 * dTrTa1 * va1 +
    -0.0158286817515286 * Ta6 * va2 +
    -0.0123918623262792 * Ta6 * rH2 +
    0.00865497207378352 * Ta5 * dTrTa2 * va1 +
    -0.0313622056127219 * Ta5 * dTrTa1 * va2 +
    0.0059883355097739 * Ta5 * dTrTa1 * rH2 +
    0.0282517594922186 * Ta5 * va3 +
    -0.00055801074931404 * Ta5 * rH3 +
    0.00216134547091048 * Ta4 * dTrTa3 * va1 +
    -0.00390324341081546 * Ta4 * dTrTa2 * va2 +
    0.0163223310714439 * Ta4 * dTrTa1 * va3 +
    -0.00150025871011703 * Ta4 * dTrTa1 * va1 * rH2 +
    0.00276956624980006 * Ta4 * dTrTa1 * rH3 +
    -0.0229190983632922 * Ta4 * va4 +
    0.00314130091223181 * Ta3 * dTrTa1 * va2 * rH2 +
    -0.0112810754291653 * Ta3 * va5 +
    0.00416439851600464 * Ta3 * rH5 +
    -0.000700256201721478 * Ta2 * dTrTa3 * va3 +
    -0.000514959299985243 * Ta2 * dTrTa1 * va3 * rH2 +
    0.00233921794871584 * Ta2 * dTrTa1 * va1 * rH4 +
    0.00619041956132346 * Ta2 * va6 +
    -0.00342955079343321 * Ta1 * dTrTa1 * va2 * rH4 +
    0.000527414639632667 * dTrTa1 * va7 +
    -0.000183752476546752 * dTrTa1 * va1 * rH6 +
    -0.0118888391328967 * va8 +
    0.000238712903990469 * va4 * rH4 +
    -0.00274527466548323 * rH8 +
    -0.00346736606571359 * Ta9 +
    -0.015821140907443 * Ta8 * dTrTa1 +
    -0.0159703972679985 * Ta8 * va1 +
    -0.00220146749570155 * Ta8 * rH1 +
    -0.0196462686116071 * Ta7 * dTrTa1 * va1 +
    0.0160930622139814 * Ta7 * va2 +
    0.0271083926542394 * Ta6 * dTrTa1 * va2 +
    -0.0169727859361079 * Ta6 * va3 +
    -0.00262019654796821 * Ta5 * va2 * rH2 +
    0.0117666226277279 * Ta5 * rH4 +
    0.00865116634722382 * Ta4 * dTrTa2 * va3 +
    -0.0318664489619453 * Ta4 * dTrTa1 * va4 +
    0.00136762123420908 * Ta4 * va3 * rH2 +
    -0.00648813541319593 * Ta2 * dTrTa2 * va5 +
    0.00283418925119063 * Ta2 * dTrTa1 * va6 +
    0.000627683891249201 * dTrTa2 * rH7 +
    0.000464486061684286 * va7 * rH2 +
    -0.012558774419946 * Ta10 +
    0.0142246701070405 * Ta9 * dTrTa1 +
    -0.0219945853668843 * Ta9 * va1 +
    0.00147989498898127 * Ta9 * rH1 +
    0.020694589513114 * Ta8 * dTrTa2 +
    -0.0159821465878725 * Ta8 * dTrTa1 * va1 +
    0.00122990587236154 * Ta8 * va2 +
    0.00774643224013198 * Ta8 * rH2 +
    0.00348972484418949 * Ta7 * dTrTa3 +
    -0.00449889353160404 * Ta7 * dTrTa2 * va1 +
    0.00150065745949661 * Ta7 * dTrTa2 * rH1 +
    -0.000617652342920564 * Ta7 * va3 +
    0.0150749840950315 * Ta7 * rH3 +
    -0.00456928274166078 * Ta6 * dTrTa1 * va3 +
    0.0132771238868905 * Ta6 * va4 +
    -0.00313385473186283 * Ta6 * va2 * rH2 +
    0.0187605036147175 * Ta5 * dTrTa1 * va4 +
    0.000600921760262751 * Ta5 * va3 * rH2 +
    -0.00662490990387182 * Ta4 * va6 +
    0.00527904629696365 * Ta4 * va2 * rH4 +
    -0.000464141239154267 * Ta3 * dTrTa1 * va6 +
    -0.00506780416680173 * Ta3 * va3 * rH4 +
    0.0040868742073381 * Ta2 * va8 +
    0.000288339820559906 * Ta1 * dTrTa2 * rH7 +
    -0.0158274027071249 * Ta1 * va9 +
    0.00170167068625823 * dTrTa2 * rH8 +
    0.00283124879915756 * dTrTa1 * va9 +
    -0.000290365909059354 * dTrTa1 * va1 * rH8 +
    -0.0131987351201934 * va10 +
    0.000543804208687463 * va1 * rH9

  Ta + UTCI_offset_normalized * 45.135 - 17.085
}

#' UTCI thermal stress categories
#'
#' Classify thermal stress based on UTCI values.
#'
#' @param utci_val UTCI value in Celsius
#' @return Factor with thermal stress category
#' @export
#' @examples
#' utci_category(c(-20, 0, 20, 30, 40))
utci_category <- function(utci_val) {
  breaks <- c(-Inf, -40, -27, -13, 0, 9, 26, 32, 38, 46, Inf)
  labels <- c(
    "Extreme cold stress", "Very strong cold stress", "strong cold stress",
    "Moderate cold stress", "Slight cold stress", "No thermal stress",
    "Moderate heat stress", "Strong heat stress", "Very strong heat stress",
    "Extreme heat stress"
  )
  cut(utci_val, breaks = breaks, labels = labels, right = FALSE)
}

#' Calculate all heat stress indices
#'
#' Calculate all heat stress indices from temperature and dewpoint.
#'
#' @param temp_c Air temperature in celsius
#' @param dewpoint_c Dewpoint temperature in celsius
#' @return Data frame with columns: temp_c, dewpoint_c, rh, wet_bulb, heat_index,
#'   wbgt, humidex
#' @export
#' @examples
#' calc_heat_indices(35, 25)
#' calc_heat_indices(c(30, 35, 40), c(20, 25, 28))
calc_heat_indices <- function(temp_c, dewpoint_c) {
  rh <- relative_humidity_from_dewpoint(temp_c, dewpoint_c)

  data.frame(
    temp_c = temp_c,
    dewpoint_c = dewpoint_c,
    rh = round(rh, 1),
    wet_bulb = round(wet_bulb_temperature(temp_c, rh), 2),
    heat_index = round(heat_index(temp_c, rh), 2),
    wbgt = round(wbgt_simple(temp_c, dewpoint_c), 2),
    humidex = round(humidex(temp_c, dewpoint_c), 2)
  )
}

#' heat stress risk categories
#'
#' Classify heat stress risk based on WBGT values using ISO 7243 guidelines.
#'
#' @param wbgt WBGT value in celsius
#' @return Factor with risk category
#' @export
#' @examples
#' wbgt_risk_category(c(25, 28, 31, 34))
wbgt_risk_category <- function(wbgt) {
  # NWS/OSHA WBGT flag-condition breaks, converted from 78/82/85/88 degF to degC.
  breaks <- c(-Inf, 25.5556, 27.7778, 29.4444, 31.1111, Inf)
  labels <- c("Low", "Moderate", "High", "Very high", "Extreme")
  cut(wbgt, breaks = breaks, labels = labels, right = FALSE)
}

#' Heat index risk categories
#'
#' Classify heat stress risk based on heat index using NWS categories.
#'
#' @param hi Heat index value in Celsius
#' @return Factor with risk category
#' @export
#' @examples
#' heat_index_risk_category(c(27, 33, 40, 46, 55))
heat_index_risk_category <- function(hi) {
  # NWS heat-index categories, converted from 80/90/103/124 degF to degC.
  breaks <- c(-Inf, 26.6667, 32.2222, 39.4444, 51.1111, Inf)
  labels <- c("Normal", "Caution", "Extreme Caution", "Danger", "Extreme Danger")
  cut(hi, breaks = breaks, labels = labels, right = FALSE)
}

.download_era5_var <- function(var_name, suffix, request_id, start_date, end_date,
                               json_file, north, south, east, west,
                               resolution, use_cache, verbose) {
  if (!is.null(json_file)) {
    era5ify_geojson(
      request_id = paste0(request_id, "_", suffix),
      variables = var_name,
      start_date = start_date,
      end_date = end_date,
      json_file = json_file,
      frequency = "daily",
      resolution = resolution,
      use_cache = use_cache,
      convert_units = TRUE,
      verbose = verbose
    )
  } else {
    era5ify_bbox(
      request_id = paste0(request_id, "_", suffix),
      variables = var_name,
      start_date = start_date,
      end_date = end_date,
      north = north, south = south, east = east, west = west,
      frequency = "daily",
      resolution = resolution,
      use_cache = use_cache,
      convert_units = TRUE,
      verbose = verbose
    )
  }
}

.validate_region <- function(json_file, north, south, east, west) {
  has_bbox <- !is.null(north) && !is.null(south) && !is.null(east) && !is.null(west)
  if (is.null(json_file) && !has_bbox) {
    stop("Must provide either json_file or bounding box coordinates (north, south, east, west)")
  }
}

#' Download daily ERA5 climate data
#'
#' Download ERA5 climate variables (temperature, humidity, wet bulb, wind,
#' solar radiation) for a region.
#'
#' @param request_id Unique identifier for the data request
#' @param start_date Start date in "YYYY-MM-DD" format
#' @param end_date End date in "YYYY-MM-DD" format
#' @param variables Character vector of variables to download. Options:
#'   "temperature", "humidity", "wet_bulb", "wind", "solar"
#' @param json_file Path to GeoJSON file defining the region
#' @param north,south,east,west Bounding box coordinates (alternative to json_file)
#' @param resolution Spatial resolution in degrees (default: 0.25)
#' @param use_cache Whether to use cached data (default: TRUE)
#' @param verbose Whether to print progress messages (default: FALSE)
#' @return data.frame with date, latitude, longitude, and requested variables
#' @export
#' @examples
#' \dontrun{
#' # Get temperature and humidity
#' climate <- GetERA5DailyClimate(
#'   request_id = "india_climate",
#'   start_date = "2023-05-01",
#'   end_date = "2023-05-31",
#'   variables = c("temperature", "humidity"),
#'   json_file = "india.geojson"
#' )
#' }
GetERA5DailyClimate <- function(request_id, start_date, end_date,
                                variables = c("temperature", "humidity"),
                                json_file = NULL,
                                north = NULL, south = NULL,
                                east = NULL, west = NULL,
                                resolution = 0.25,
                                use_cache = TRUE,
                                verbose = FALSE) {
  .validate_region(json_file, north, south, east, west)

  valid_vars <- c("temperature", "humidity", "wet_bulb", "wind", "solar")
  invalid <- setdiff(variables, valid_vars)
  if (length(invalid) > 0) {
    stop(
      "Invalid variables: ", paste(invalid, collapse = ", "),
      ". Valid options: ", paste(valid_vars, collapse = ", ")
    )
  }

  download_var <- function(var_name, suffix) {
    .download_era5_var(
      var_name, suffix, request_id, start_date, end_date,
      json_file, north, south, east, west, resolution, use_cache, verbose
    )
  }

  result <- NULL

  if ("temperature" %in% variables || "humidity" %in% variables ||
    "wet_bulb" %in% variables) {
    era5_temp <- download_var("2m_temperature", "temp") %>%
      mutate(temp_c = .data$value, date = as.Date(.data$datetime)) %>%
      select("date", "latitude", "longitude", "temp_c")
    result <- era5_temp
  }

  if ("humidity" %in% variables || "wet_bulb" %in% variables) {
    era5_dewpoint <- download_var("2m_dewpoint_temperature", "dewpoint") %>%
      mutate(dewpoint_c = .data$value, date = as.Date(.data$datetime)) %>%
      select("date", "latitude", "longitude", "dewpoint_c")
    result <- result %>%
      inner_join(era5_dewpoint, by = c("date", "latitude", "longitude")) %>%
      mutate(rh = relative_humidity_from_dewpoint(.data$temp_c, .data$dewpoint_c))
  }

  if ("wet_bulb" %in% variables) {
    result <- result %>%
      mutate(wet_bulb = wet_bulb_temperature(.data$temp_c, .data$rh))
  }

  if ("wind" %in% variables) {
    era5_u <- download_var("10m_u_component_of_wind", "wind_u") %>%
      mutate(wind_u = .data$value, date = as.Date(.data$datetime)) %>%
      select("date", "latitude", "longitude", "wind_u")
    era5_v <- download_var("10m_v_component_of_wind", "wind_v") %>%
      mutate(wind_v = .data$value, date = as.Date(.data$datetime)) %>%
      select("date", "latitude", "longitude", "wind_v")

    wind_data <- era5_u %>%
      inner_join(era5_v, by = c("date", "latitude", "longitude")) %>%
      mutate(wind_speed = sqrt(.data$wind_u^2 + .data$wind_v^2)) %>%
      select("date", "latitude", "longitude", "wind_speed")

    if (is.null(result)) {
      result <- wind_data
    } else {
      result <- result %>%
        inner_join(wind_data, by = c("date", "latitude", "longitude"))
    }
  }

  if ("solar" %in% variables) {
    era5_solar <- download_var("surface_solar_radiation_downwards", "solar") %>%
      mutate(solar_radiation = .data$value, date = as.Date(.data$datetime)) %>%
      select("date", "latitude", "longitude", "solar_radiation")

    if (is.null(result)) {
      result <- era5_solar
    } else {
      result <- result %>%
        inner_join(era5_solar, by = c("date", "latitude", "longitude"))
    }
  }

  result
}

#' @rdname GetERA5DailyClimate
#' @export
get_era5_daily_climate <- GetERA5DailyClimate

#' Download daily ERA5 temperature data
#'
#' @param request_id Unique identifier for the data request
#' @param start_date Start date in "YYYY-MM-DD" format
#' @param end_date End date in "YYYY-MM-DD" format
#' @param json_file Path to GeoJSON file defining the region
#' @param north,south,east,west Bounding box coordinates (alternative to json_file)
#' @param resolution Spatial resolution in degrees (default: 0.25)
#' @param use_cache Whether to use cached data (default: TRUE)
#' @param verbose Whether to print progress messages (default: FALSE)
#' @return data.frame with date, latitude, longitude, temp_c
#' @export
#' @examples
#' \dontrun{
#' temp <- GetERA5DailyTemperature(
#'   request_id = "india_temp",
#'   start_date = "2023-05-01",
#'   end_date = "2023-05-31",
#'   json_file = "india.geojson"
#' )
#' }
GetERA5DailyTemperature <- function(request_id, start_date, end_date,
                                    json_file = NULL,
                                    north = NULL, south = NULL,
                                    east = NULL, west = NULL,
                                    resolution = 0.25,
                                    use_cache = TRUE,
                                    verbose = FALSE) {
  GetERA5DailyClimate(request_id, start_date, end_date,
    variables = "temperature",
    json_file = json_file,
    north = north, south = south, east = east, west = west,
    resolution = resolution, use_cache = use_cache, verbose = verbose
  )
}

#' @rdname GetERA5DailyTemperature
#' @export
get_era5_daily_temperature <- GetERA5DailyTemperature

#' Download daily ERA5 humidity data
#'
#' Downloads temperature, dewpoint, and calculates relative humidity.
#'
#' @inheritParams GetERA5DailyTemperature
#' @return data.frame with date, latitude, longitude, temp_c, dewpoint_c, rh
#' @export
#' @examples
#' \dontrun{
#' humidity <- GetERA5DailyHumidity(
#'   request_id = "india_humidity",
#'   start_date = "2023-05-01",
#'   end_date = "2023-05-31",
#'   json_file = "india.geojson"
#' )
#' }
GetERA5DailyHumidity <- function(request_id, start_date, end_date,
                                 json_file = NULL,
                                 north = NULL, south = NULL,
                                 east = NULL, west = NULL,
                                 resolution = 0.25,
                                 use_cache = TRUE,
                                 verbose = FALSE) {
  GetERA5DailyClimate(request_id, start_date, end_date,
    variables = "humidity",
    json_file = json_file,
    north = north, south = south, east = east, west = west,
    resolution = resolution, use_cache = use_cache, verbose = verbose
  )
}

#' @rdname GetERA5DailyHumidity
#' @export
get_era5_daily_humidity <- GetERA5DailyHumidity

#' Download daily ERA5 wet bulb temperature data
#'
#' Downloads temperature, dewpoint, and calculates RH and wet bulb temperature.
#'
#' @inheritParams GetERA5DailyTemperature
#' @return data.frame with date, latitude, longitude, temp_c, dewpoint_c, rh, wet_bulb
#' @export
#' @examples
#' \dontrun{
#' wetbulb <- GetERA5DailyWetBulb(
#'   request_id = "india_wetbulb",
#'   start_date = "2023-05-01",
#'   end_date = "2023-05-31",
#'   json_file = "india.geojson"
#' )
#' }
GetERA5DailyWetBulb <- function(request_id, start_date, end_date,
                                json_file = NULL,
                                north = NULL, south = NULL,
                                east = NULL, west = NULL,
                                resolution = 0.25,
                                use_cache = TRUE,
                                verbose = FALSE) {
  GetERA5DailyClimate(request_id, start_date, end_date,
    variables = "wet_bulb",
    json_file = json_file,
    north = north, south = south, east = east, west = west,
    resolution = resolution, use_cache = use_cache, verbose = verbose
  )
}

#' @rdname GetERA5DailyWetBulb
#' @export
get_era5_daily_wet_bulb <- GetERA5DailyWetBulb

#' Download daily ERA5 wind data
#'
#' Downloads 10m wind components and calculates wind speed.
#'
#' @inheritParams GetERA5DailyTemperature
#' @return data.frame with date, latitude, longitude, wind_speed
#' @export
#' @examples
#' \dontrun{
#' wind <- GetERA5DailyWind(
#'   request_id = "india_wind",
#'   start_date = "2023-05-01",
#'   end_date = "2023-05-31",
#'   json_file = "india.geojson"
#' )
#' }
GetERA5DailyWind <- function(request_id, start_date, end_date,
                             json_file = NULL,
                             north = NULL, south = NULL,
                             east = NULL, west = NULL,
                             resolution = 0.25,
                             use_cache = TRUE,
                             verbose = FALSE) {
  GetERA5DailyClimate(request_id, start_date, end_date,
    variables = "wind",
    json_file = json_file,
    north = north, south = south, east = east, west = west,
    resolution = resolution, use_cache = use_cache, verbose = verbose
  )
}

#' @rdname GetERA5DailyWind
#' @export
get_era5_daily_wind <- GetERA5DailyWind

#' Download ERA5 data and calculate heat stress indices
#'
#' Download ERA5 temperature, dewpoint, and wind data for a region and calculate
#' heat stress indices.
#'
#' @param request_id Unique identifier for the data request
#' @param start_date Start date in "YYYY-MM-DD" format
#' @param end_date End date in "YYYY-MM-DD" format
#' @param json_file Path to GeoJSON file defining the region (for geojson method)
#' @param north Northern latitude boundary (for bbox method)
#' @param south Southern latitude boundary (for bbox method)
#' @param east Eastern longitude boundary (for bbox method)
#' @param west Western longitude boundary (for bbox method)
#' @param solar_load Whether to include solar radiation in calculations (default: FALSE).
#'   When TRUE, downloads solar radiation data and uses it for WBGT and UTCI.
#' @param resolution Spatial resolution in degrees (default: 0.25)
#' @param use_cache Whether to use cached data if available (default: TRUE)
#' @param verbose Whether to print progress messages (default: FALSE)
#' @return data.frame with columns: date, latitude, longitude, temp_c, dewpoint_c,
#'   wind_speed, rh, wet_bulb, heat_index, wbgt, utci, humidex, wbgt_risk,
#'   heat_index_risk, utci_stress. When solar_load=TRUE, also includes solar_radiation.
#' @export
#' @examples
#' \dontrun{
#' heat_data <- GetERA5DailyHeatIndexData(
#'   request_id = "india_heat_2023",
#'   start_date = "2023-05-01",
#'   end_date = "2023-05-31",
#'   json_file = "india.geojson"
#' )
#'
#' # With solar radiation for outdoor WBGT
#' heat_data <- GetERA5DailyHeatIndexData(
#'   request_id = "india_heat_2023_solar",
#'   start_date = "2023-05-01",
#'   end_date = "2023-05-31",
#'   json_file = "india.geojson",
#'   solar_load = TRUE
#' )
#' }
GetERA5DailyHeatIndexData <- function(request_id, start_date, end_date,
                                      json_file = NULL,
                                      north = NULL, south = NULL,
                                      east = NULL, west = NULL,
                                      solar_load = FALSE,
                                      resolution = 0.25,
                                      use_cache = TRUE,
                                      verbose = FALSE) {
  .validate_region(json_file, north, south, east, west)

  variables <- if (solar_load) {
    c("temperature", "humidity", "wind", "solar")
  } else {
    c("temperature", "humidity", "wind")
  }

  climate_data <- GetERA5DailyClimate(
    request_id = request_id,
    start_date = start_date,
    end_date = end_date,
    variables = variables,
    json_file = json_file,
    north = north, south = south, east = east, west = west,
    resolution = resolution,
    use_cache = use_cache,
    verbose = verbose
  )

  if (solar_load) {
    heat_data <- climate_data %>%
      mutate(
        # Convert solar radiation from J/m²/day to W/m² (average power)
        solar_radiation_wm2 = .data$solar_radiation / 86400,
        wet_bulb = wet_bulb_temperature(.data$temp_c, .data$rh),
        heat_index = heat_index(.data$temp_c, .data$rh),
        tmrt = mean_radiant_temperature(.data$temp_c, .data$solar_radiation_wm2, .data$wind_speed),
        wbgt = wbgt_simple(.data$temp_c, .data$dewpoint_c),
        utci = utci(.data$temp_c,
          wind_speed = .data$wind_speed,
          dewpoint_c = .data$dewpoint_c, tmrt = .data$tmrt
        ),
        humidex = humidex(.data$temp_c, .data$dewpoint_c),
        wbgt_risk = wbgt_risk_category(.data$wbgt),
        heat_index_risk = heat_index_risk_category(.data$heat_index),
        utci_stress = utci_category(.data$utci)
      ) %>%
      select(-"tmrt", -"solar_radiation_wm2")
  } else {
    heat_data <- climate_data %>%
      mutate(
        wet_bulb = wet_bulb_temperature(.data$temp_c, .data$rh),
        heat_index = heat_index(.data$temp_c, .data$rh),
        wbgt = wbgt_simple(.data$temp_c, .data$dewpoint_c),
        utci = utci(.data$temp_c,
          wind_speed = .data$wind_speed,
          dewpoint_c = .data$dewpoint_c, tmrt = NULL
        ),
        humidex = humidex(.data$temp_c, .data$dewpoint_c),
        wbgt_risk = wbgt_risk_category(.data$wbgt),
        heat_index_risk = heat_index_risk_category(.data$heat_index),
        utci_stress = utci_category(.data$utci)
      )
  }

  heat_data
}

#' @rdname GetERA5DailyHeatIndexData
#' @export
get_era5_daily_heat_index_data <- GetERA5DailyHeatIndexData

#' @rdname GetERA5DailyHeatIndexData
#' @export
GetERA5DailyHeatData <- GetERA5DailyHeatIndexData

#' @rdname GetERA5DailyHeatIndexData
#' @export
get_era5_daily_heat_data <- GetERA5DailyHeatIndexData

#' Get monthly ERA5 heat stress index data
#'
#' Download ERA5 heat stress indices aggregated to a given month.
#'
#' @param request_id Unique identifier for the data request
#' @param year Year (e.g., 2023)
#' @param month Month (1-12)
#' @param json_file Path to GeoJSON file defining the region
#' @param north,south,east,west Bounding box coordinates (alternative to json_file)
#' @param solar_load Whether to include solar radiation (default: FALSE)
#' @param resolution Spatial resolution in degrees (default: 0.25)
#' @param use_cache Whether to use cached data (default: TRUE)
#' @param verbose Whether to print progress messages (default: FALSE)
#' @return data.frame with monthly mean values for each grid point
#' @export
#' @examples
#' \dontrun{
#' heat_may <- GetERA5MonthlyHeatIndexData(
#'   request_id = "india_may2023",
#'   year = 2023,
#'   month = 5,
#'   json_file = "india.geojson"
#' )
#' }
GetERA5MonthlyHeatIndexData <- function(request_id, year, month,
                                        json_file = NULL,
                                        north = NULL, south = NULL,
                                        east = NULL, west = NULL,
                                        solar_load = FALSE,
                                        resolution = 0.25,
                                        use_cache = TRUE,
                                        verbose = FALSE) {
  start_date <- sprintf("%d-%02d-01", year, month)
  next_month <- if (month == 12) sprintf("%d-01-01", year + 1) else sprintf("%d-%02d-01", year, month + 1)
  end_date <- as.character(as.Date(next_month) - 1)

  daily_data <- GetERA5DailyHeatData(
    request_id = request_id,
    start_date = start_date,
    end_date = end_date,
    json_file = json_file,
    north = north, south = south, east = east, west = west,
    solar_load = solar_load,
    resolution = resolution,
    use_cache = use_cache,
    verbose = verbose
  )

  numeric_cols <- c(
    "temp_c", "dewpoint_c", "wind_speed", "rh", "wet_bulb",
    "heat_index", "wbgt", "utci", "humidex"
  )
  if (solar_load) numeric_cols <- c(numeric_cols, "solar_radiation")

  monthly_data <- daily_data %>%
    group_by(.data$latitude, .data$longitude) %>%
    summarise(
      year = year,
      month = month,
      across(any_of(numeric_cols), ~ mean(.x, na.rm = TRUE)),
      .groups = "drop"
    ) %>%
    mutate(
      wbgt_risk = wbgt_risk_category(.data$wbgt),
      heat_index_risk = heat_index_risk_category(.data$heat_index),
      utci_stress = utci_category(.data$utci)
    )

  monthly_data
}

#' @rdname GetERA5MonthlyHeatIndexData
#' @export
get_era5_monthly_heat_index_data <- GetERA5MonthlyHeatIndexData

#' @rdname GetERA5MonthlyHeatIndexData
#' @export
GetERA5MonthlyHeatData <- GetERA5MonthlyHeatIndexData

#' @rdname GetERA5MonthlyHeatIndexData
#' @export
get_era5_monthly_heat_data <- GetERA5MonthlyHeatIndexData
