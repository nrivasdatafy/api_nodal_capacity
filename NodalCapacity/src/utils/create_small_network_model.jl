"""
Create a small electrical network model in OpenDSS format.

# Arguments
- `master_file::String`: Path to the output OpenDSS file.

# Description
Generates an OpenDSS model representing a small electrical network:
- One AT/MT transformer.
- Four medium voltage (MT) lines.
- Three MT/BT transformers.
- Multiple low voltage (BT) lines, loads, and PV systems under each transformer.

The resulting network is written to the specified file and can be compiled with OpenDSS.
"""
function create_small_network_model(master_file::String)
    open(master_file, "w") do io
        println(io, "Clear")
        println(io, "New Circuit.test_case basekv=11 phases=3")

        # AT/MT Transformer
        println(io, "New Transformer.AT_MT Buses=[Bus_AT, Bus_MT1] kvas=[10000, 10000] kvs=[11, 12.47] conn=[delta, wye] xhl=2.5 %loadloss=0")

        # Medium Voltage (MT) Lines
        println(io, "New Line.MT_Line1 Bus1=Bus_MT1 Bus2=Bus_MT2 phases=3 length=1 units=km Linecode=240sq")
        println(io, "New Line.MT_Line2 Bus1=Bus_MT2 Bus2=Bus_MT3 phases=3 length=1 units=km Linecode=240sq")
        println(io, "New Line.MT_Line3 Bus1=Bus_MT3 Bus2=Bus_MT4 phases=3 length=0.8 units=km Linecode=240sq")
        println(io, "New Line.MT_Line4 Bus1=Bus_MT4 Bus2=Bus_MT5 phases=3 length=0.6 units=km Linecode=240sq")

        # MT/BT Transformers
        println(io, "New Transformer.MT_BT1 Buses=[Bus_MT2, Bus_BT1] kvas=[250, 250] kvs=[12.47, 0.4] conn=[delta, wye] xhl=2.5")
        println(io, "New Transformer.MT_BT2 Buses=[Bus_MT3, Bus_BT2] kvas=[250, 250] kvs=[12.47, 0.4] conn=[delta, wye] xhl=2.5")
        println(io, "New Transformer.MT_BT3 Buses=[Bus_MT4, Bus_BT3] kvas=[250, 250] kvs=[12.47, 0.4] conn=[delta, wye] xhl=2.5")

        # Low Voltage (BT) Lines and Loads
        for i in 1:3
            println(io, "New Line.BT_Line1_$(i) Bus1=Bus_BT1 Bus2=Bus_BT1_$(i) phases=1 length=0.2 units=km Linecode=16sq")
            println(io, "New Line.BT_Line2_$(i) Bus1=Bus_BT2 Bus2=Bus_BT2_$(i) phases=1 length=0.2 units=km Linecode=16sq")
            println(io, "New Line.BT_Line3_$(i) Bus1=Bus_BT3 Bus2=Bus_BT3_$(i) phases=1 length=0.2 units=km Linecode=16sq")

            println(io, "New Load.Load_BT1_$(i) Bus1=Bus_BT1_$(i) phases=1 kV=0.230 kW=$(10 + i * 5) pf=0.95 model=1 Vminpu=0.85 Vmaxpu=1.20")
            println(io, "New Load.Load_BT2_$(i) Bus1=Bus_BT2_$(i) phases=1 kV=0.230 kW=$(10 + i * 5) pf=0.95 model=1 Vminpu=0.85 Vmaxpu=1.20")
            println(io, "New Load.Load_BT3_$(i) Bus1=Bus_BT3_$(i) phases=1 kV=0.230 kW=$(10 + i * 5) pf=0.95 model=1 Vminpu=0.85 Vmaxpu=1.20")
        end

        # PV Systems
        for i in 1:3
            println(io, "New PVSystem.PV_BT1_$(i) Bus1=Bus_BT1_$(i) phases=1 kV=0.230 kVA=5 irrad=1 Pmpp=5 model=1 Vminpu=0.85 Vmaxpu=1.20")
            println(io, "New PVSystem.PV_BT2_$(i) Bus1=Bus_BT2_$(i) phases=1 kV=0.230 kVA=5 irrad=1 Pmpp=5 model=1 Vminpu=0.85 Vmaxpu=1.20")
            println(io, "New PVSystem.PV_BT3_$(i) Bus1=Bus_BT3_$(i) phases=1 kV=0.230 kVA=5 irrad=1 Pmpp=5 model=1 Vminpu=0.85 Vmaxpu=1.20")
        end

        # Solve command
        println(io, "Solve")
    end
end