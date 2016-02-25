#! /bin/sh

for pred in optimal worst not-taken taken bwd-taken; do
    sed -e "s#%PRED%#"$pred"#" \
        -e "s#%IDXFUN%##" \
        -e "s#%FAST%##" \
        -e "s#%CONF%#../configurations/patmos-config-bp-16.pml#" \
        -e "s#%DIR%#work_"$pred"#" \
        < configuration.rb.template > ../configuration.rb
    ruby run.rb
done

for size in 16 1024; do
    for pred in 2bitc; do
        for fast in false; do
            for idxfun in local gshare; do
                sed -e "s#%PRED%#"$pred"#" \
                    -e "s#%IDXFUN%#"$idxfun"#" \
                    -e "s#%FAST%#"$fast"#" \
                    -e "s#%CONF%#../configurations/patmos-config-bp-"$size".pml#" \
                    -e "s#%DIR%#work_"$pred"_"$idxfun"_"$fast"_"$size"#" \
                    < configuration.rb.template > ../configuration.rb
                ruby run.rb
            done
        done
        for fast in true; do
            for idxfun in local; do
                sed -e "s#%PRED%#"$pred"#" \
                    -e "s#%IDXFUN%#"$idxfun"#" \
                    -e "s#%FAST%#"$fast"#" \
                    -e "s#%CONF%#../configurations/patmos-config-bp-"$size".pml#" \
                    -e "s#%DIR%#work_"$pred"_"$idxfun"_"$fast"_"$size"#" \
                    < configuration.rb.template > ../configuration.rb
                ruby run.rb
            done
        done
    done
done

for size in 16 32 64 128 256 512 1024 2048; do
    for pred in 2bitc; do
        for fast in true false; do
            for idxfun in gshare; do
                sed -e "s#%PRED%#"$pred"#" \
                    -e "s#%IDXFUN%#"$idxfun"#" \
                    -e "s#%FAST%#"$fast"#" \
                    -e "s#%CONF%#../configurations/patmos-config-bp-"$size".pml#" \
                    -e "s#%DIR%#work_speed_"$fast"_"$size"#" \
                    < configuration.rb.template > ../configuration.rb
                ruby run.rb
            done
        done
    done
done
