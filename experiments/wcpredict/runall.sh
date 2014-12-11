#! /bin/sh

for pred in optimal worst not-taken taken bwd-taken; do
    sed -e "s#%PRED%#"$pred"#" \
        -e "s#%DIR%#work_"$pred"#" \
        -e "s#%CONF%#../configurations/patmos-config-bp-16.pml#" \
        < configuration.rb.template > ../configuration.rb
    ruby1.9.1 run.rb
done

for pred in 1bit 2bitc 2bith; do
    sed -e "s#%PRED%#"$pred"#" \
        -e "s#%DIR%#work_"$pred"_small#" \
        -e "s#%CONF%#../configurations/patmos-config-bp-16.pml#" \
        < configuration.rb.template > ../configuration.rb
    ruby1.9.1 run.rb
done

for pred in 1bit 2bitc 2bith; do
    sed -e "s#%PRED%#"$pred"#" \
        -e "s#%DIR%#work_"$pred"_large#" \
        -e "s#%CONF%#../configurations/patmos-config-bp-1024.pml#" \
        < configuration.rb.template > ../configuration.rb
    ruby1.9.1 run.rb
done
