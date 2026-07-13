#!/usr/bin/env python3
"""Dimension drone-carried OAI DU payload profiles.

Edit MISSION, COMPONENTS, BATTERIES, PROFILES, or DRONES below, then run:

    python3 scripts/drone-du-sizing.py

Formula provenance:
- The payload battery equation is a constant-power energy budget: E = P * t,
  derated by DC efficiency and usable battery fraction. The calculator then
  selects the smallest listed real battery whose nominal Wh is large enough.
- This is consistent with UAV endurance literature that estimates endurance
  from available battery energy divided by required power, then refines the
  estimate with battery-discharge and propulsion models:
  Hwang, Cha, Jung, "Practical Endurance Estimation for Minimizing Energy
  Consumption of Multirotor Unmanned Aerial Vehicles", Energies, 2018,
  https://www.mdpi.com/1996-1073/11/9/2221
  Abdilla, Richards, Burrow, "Power and Endurance Modelling of
  Battery-Powered Rotorcraft", 2015,
  https://www.semanticscholar.org/paper/Power-and-endurance-modelling-of-battery-powered-Abdilla-Richards/76ffb97d686447bca76d36a079762e88c6f4bc30
- The drone payload-rating gate is not a published formula. It is a conservative
  lab margin rule: required rating = payload mass / allowed rating utilization.
  Rotary-wing UAV papers such as Zeng, Xu, Zhang, "Energy Minimization for
  Wireless Communication with Rotary-Wing UAV", IEEE TWC, 2019, show why
  payload/proportional propulsion margins matter, but they do not define this
  70 percent procurement rule.
"""

MISSION = {
    "minutes": 20.0,
    "electrical_reserve_factor": 1.30,
    "usable_battery_fraction": 0.80,
    "dc_efficiency": 0.88,
    "max_payload_rating_utilization": 0.70,
}

COMPONENTS = {
    # Performance-mode design power budgets. These are intentionally ceilings
    # for procurement sizing, not idle/average measurements.
    "pi_5": {"mass_g": 46.0, "power_w": 25.5},
    "jetson_orin_nano_carrier": {"mass_g": 250.0, "power_w": 35.0},
    "mini_pc_x86": {"mass_g": 650.0, "power_w": 65.0},
    "usrp_b205mini_i": {"mass_g": 24.0, "power_w": 5.0},
    "usrp_b210": {"mass_g": 350.0, "power_w": 8.0},
    "quectel_rm500q_gl_kit": {"mass_g": 180.0, "power_w": 12.0},
    "rf_timing_light": {"mass_g": 180.0, "power_w": 8.0},
    "rf_timing_b210": {"mass_g": 250.0, "power_w": 10.0},
    "rf_timing_b210_heavy": {"mass_g": 250.0, "power_w": 15.0},
    "power_mount_light": {"mass_g": 300.0, "power_w": 0.0},
    "power_mount_medium": {"mass_g": 350.0, "power_w": 0.0},
    "power_mount_heavy": {"mass_g": 500.0, "power_w": 0.0},
    "dual_radio_extra": {"mass_g": 650.0, "power_w": 45.0},
}

BATTERIES = {
    "auline_v45_4s_3000": {
        "label": "Auline V45 3000 mAh 4S1P 14.8 V Li-ion XT60",
        "voltage_v": 14.8,
        "capacity_mah": 3000,
        "energy_wh": 44.4,
        "mass_g": 208.0,
        "max_current_a": 45.0,
        "reference": "https://www.racedayquads.com/products/auline-18650-v45-4s-3000mah-14-8v-45a-li-ion-battery-xt60",
    },
    "auline_s70_6s_5000": {
        "label": "Auline S70 Ultra 5000 mAh 6S1P 22.2 V Li-ion XT60",
        "voltage_v": 22.2,
        "capacity_mah": 5000,
        "energy_wh": 111.0,
        "mass_g": 429.0,
        "max_current_a": 70.0,
        "reference": "https://morevolts.ca/auline-s70-ultra-5000mah-6s1p-22-2v-70a-battery-xt60/",
    },
    "tattu_gtech_6s_5000": {
        "label": "Tattu G-Tech 5000 mAh 6S1P 22.2 V 45C LiPo XT60",
        "voltage_v": 22.2,
        "capacity_mah": 5000,
        "energy_wh": 111.0,
        "mass_g": 702.0,
        "max_current_a": 225.0,
        "reference": "https://store.foxtech.com/g-tech-6s-5000mah-22-2v-45c-high-discharge-lipo-battery/",
    },
}

PROFILES = {
    "A": {
        "label": "Minimum proof: Pi 5 + USRP B205mini-i + Quectel",
        "components": [
            "pi_5",
            "usrp_b205mini_i",
            "quectel_rm500q_gl_kit",
            "rf_timing_light",
            "power_mount_light",
        ],
    },
    "B": {
        "label": "B210 validation: Jetson-class compute + B210 + Quectel",
        "components": [
            "jetson_orin_nano_carrier",
            "usrp_b210",
            "quectel_rm500q_gl_kit",
            "rf_timing_b210",
            "power_mount_medium",
        ],
    },
    "C": {
        "label": "Actual mini-PC class: x86 mini-PC + B210 + Quectel",
        "components": [
            "mini_pc_x86",
            "usrp_b210",
            "quectel_rm500q_gl_kit",
            "rf_timing_b210_heavy",
            "power_mount_heavy",
        ],
    },
    "D": {
        "label": "Dual-radio prototype: mini-PC class + extra RF margin",
        "components": [
            "mini_pc_x86",
            "usrp_b210",
            "quectel_rm500q_gl_kit",
            "rf_timing_b210_heavy",
            "power_mount_heavy",
            "dual_radio_extra",
        ],
    },
}

DRONES = {
    "Freefly Astro Max": {
        "payload_gate_kg": 3.0,
        "price_usd": 22995.0,
        "note": "Compact research option; too tight for mini-PC packaging.",
    },
    "DJI Matrice 350 RTK": {
        "payload_gate_kg": 2.73,
        "price_usd": 11500.0,
        "note": "Gross-weight planning margin; verify custom mount limits.",
    },
    "DJI Matrice 400": {
        "payload_gate_kg": 6.0,
        "price_usd": 10400.0,
        "flight_curve": [(0.0, 59.0), (3.0, 44.0), (6.0, 31.0)],
        "note": "Balanced first choice for mini-PC + B210 + Quectel.",
    },
    "Inspired Flight IF1200A": {
        "payload_gate_kg": 8.6,
        "price_usd": 32000.0,
        "note": "Heavy-lift research choice with generous integration margin.",
    },
    "Skyfront Perimeter 8": {
        "payload_gate_kg": 10.0,
        "price_usd": 49900.0,
        "note": "Endurance-first hybrid; larger than needed for first proofs.",
    },
}

FLIGHT_TIME_RESERVE_FACTOR = 0.75


def select_battery(required_wh, payload_power_w):
    candidates = []
    for key, battery in BATTERIES.items():
        current_a = payload_power_w / battery["voltage_v"]
        if battery["energy_wh"] >= required_wh and battery["max_current_a"] >= current_a:
            candidates.append((battery["energy_wh"], battery["mass_g"], key, battery))
    if not candidates:
        raise ValueError(
            f"No listed battery can provide {required_wh:.1f} Wh "
            f"and {payload_power_w:.1f} W"
        )
    _, _, key, battery = min(candidates)
    return key, battery


def profile_result(profile):
    fixed_mass_g = sum(COMPONENTS[name]["mass_g"] for name in profile["components"])
    payload_power_w = sum(COMPONENTS[name]["power_w"] for name in profile["components"])
    energy_wh = (
        payload_power_w
        * MISSION["minutes"]
        / 60.0
        * MISSION["electrical_reserve_factor"]
        / (MISSION["dc_efficiency"] * MISSION["usable_battery_fraction"])
    )
    battery_key, battery = select_battery(energy_wh, payload_power_w)
    battery_g = battery["mass_g"]
    payload_g = fixed_mass_g + battery_g
    required_rating_kg = payload_g / 1000.0 / MISSION["max_payload_rating_utilization"]
    return {
        "fixed_mass_g": fixed_mass_g,
        "payload_power_w": payload_power_w,
        "battery_wh": energy_wh,
        "battery_key": battery_key,
        "battery_label": battery["label"],
        "battery_nominal_wh": battery["energy_wh"],
        "battery_g": battery_g,
        "payload_kg": payload_g / 1000.0,
        "required_rating_kg": required_rating_kg,
    }


def fit_label(required_rating_kg, payload_gate_kg):
    return "Fit" if payload_gate_kg >= required_rating_kg else "No"


def cheapest_drone(required_rating_kg):
    candidates = [
        (name, spec)
        for name, spec in DRONES.items()
        if spec["payload_gate_kg"] >= required_rating_kg
    ]
    return min(candidates, key=lambda item: item[1]["price_usd"])


def interpolate_flight_minutes(payload_kg, flight_curve):
    if not flight_curve:
        return None
    points = sorted(flight_curve)
    if payload_kg <= points[0][0]:
        return points[0][1]
    for (x0, y0), (x1, y1) in zip(points, points[1:]):
        if payload_kg <= x1:
            ratio = (payload_kg - x0) / (x1 - x0)
            return y0 + ratio * (y1 - y0)
    return points[-1][1]


def main():
    results = {key: profile_result(profile) for key, profile in PROFILES.items()}

    print("# Drone DU Sizing Results\n")
    print(
        "Formula: battery Wh = power W * mission hours * reserve / "
        "(DC efficiency * usable battery fraction)"
    )
    print("Battery selection = smallest listed real battery meeting Wh and current\n")
    print(
        "Required drone payload rating = computed payload kg / "
        "max payload rating utilization\n"
    )

    print("| ID | Configuration | Fixed g | Design power W | Required Wh | Selected battery | Battery nominal Wh | Battery g | Payload kg | Required drone rating kg |")
    print("|---|---|---:|---:|---:|---|---:|---:|---:|---:|")
    for key, result in results.items():
        print(
            f"| {key} | {PROFILES[key]['label']} | "
            f"{result['fixed_mass_g']:.0f} | {result['payload_power_w']:.0f} | "
            f"{result['battery_wh']:.1f} | {result['battery_label']} | "
            f"{result['battery_nominal_wh']:.1f} | {result['battery_g']:.0f} | "
            f"{result['payload_kg']:.2f} | {result['required_rating_kg']:.2f} |"
        )

    print("\n| Drone | Payload gate kg | Price USD | A | B | C | D | Note |")
    print("|---|---:|---:|---|---|---|---|---|")
    for drone, spec in DRONES.items():
        fits = [
            fit_label(results[key]["required_rating_kg"], spec["payload_gate_kg"])
            for key in ["A", "B", "C", "D"]
        ]
        print(
            f"| {drone} | {spec['payload_gate_kg']:.2f} | ${spec['price_usd']:,.0f} | "
            f"{fits[0]} | {fits[1]} | {fits[2]} | {fits[3]} | {spec['note']} |"
        )

    print("\n| ID | Cheapest compatible listed drone | Drone cost USD | Selected battery | Ideal flight min | Planning flight min |")
    print("|---|---|---:|---|---:|---:|")
    for key, result in results.items():
        drone, spec = cheapest_drone(result["required_rating_kg"])
        ideal_flight = interpolate_flight_minutes(result["payload_kg"], spec.get("flight_curve"))
        planning_flight = ideal_flight * FLIGHT_TIME_RESERVE_FACTOR if ideal_flight is not None else None
        ideal_text = f"{ideal_flight:.1f}" if ideal_flight is not None else "unknown"
        planning_text = f"{planning_flight:.1f}" if planning_flight is not None else "unknown"
        print(
            f"| {key} | {drone} | ${spec['price_usd']:,.0f} | "
            f"{result['battery_label']} | "
            f"{ideal_text} | {planning_text} |"
        )


if __name__ == "__main__":
    main()
