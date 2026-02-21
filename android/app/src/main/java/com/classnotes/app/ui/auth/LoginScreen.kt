package com.classnotes.app.ui.auth

import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.animation.slideInVertically
import androidx.compose.animation.slideOutVertically
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.interaction.MutableInteractionSource
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.BasicTextField
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.ArrowDropDown
import androidx.compose.material.icons.filled.AutoStories
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.DropdownMenu
import androidx.compose.material3.DropdownMenuItem
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.OutlinedTextFieldDefaults
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.focus.FocusRequester
import androidx.compose.ui.focus.focusRequester
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalFocusManager
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.classnotes.app.service.AuthService
import com.classnotes.app.ui.theme.Teal
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch

enum class CountryCode(val code: String, val flag: String, val placeholder: String, val minDigits: Int) {
    INDIA("+91", "\uD83C\uDDEE\uD83C\uDDF3", "98765 43210", 10),
    US("+1", "\uD83C\uDDFA\uD83C\uDDF8", "(555) 123-4567", 10);
}

@Composable
fun LoginScreen(
    authService: AuthService,
    onLoginSuccess: (needsOnboarding: Boolean) -> Unit
) {
    var phoneNumber by remember { mutableStateOf("") }
    var otpCode by remember { mutableStateOf("") }
    var showOTPField by remember { mutableStateOf(false) }
    var isLoading by remember { mutableStateOf(false) }
    var errorMessage by remember { mutableStateOf<String?>(null) }
    var selectedCountry by remember { mutableStateOf(CountryCode.INDIA) }
    var countryMenuExpanded by remember { mutableStateOf(false) }

    val scope = remember { CoroutineScope(Dispatchers.Main) }

    Column(
        modifier = Modifier
            .fillMaxSize()
            .padding(horizontal = 32.dp),
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        Spacer(modifier = Modifier.weight(1f))

        // App branding
        Icon(
            imageVector = Icons.Filled.AutoStories,
            contentDescription = "ClassNotes",
            modifier = Modifier.size(64.dp),
            tint = Teal
        )
        Spacer(modifier = Modifier.height(12.dp))
        Text(
            text = "ClassNotes",
            style = MaterialTheme.typography.headlineLarge,
            fontWeight = FontWeight.Bold
        )
        Spacer(modifier = Modifier.height(8.dp))
        Text(
            text = "Share & find class notes easily",
            style = MaterialTheme.typography.bodyLarge,
            color = MaterialTheme.colorScheme.onSurfaceVariant
        )
        Spacer(modifier = Modifier.height(48.dp))

        AnimatedVisibility(
            visible = !showOTPField,
            enter = fadeIn() + slideInVertically(),
            exit = fadeOut() + slideOutVertically()
        ) {
            // Phone input section
            Column(horizontalAlignment = Alignment.CenterHorizontally) {
                Text(
                    text = "Enter your phone number",
                    style = MaterialTheme.typography.titleMedium,
                    fontWeight = FontWeight.SemiBold
                )
                Spacer(modifier = Modifier.height(16.dp))

                Row(
                    modifier = Modifier.fillMaxWidth(),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    // Country code picker
                    Box {
                        Row(
                            modifier = Modifier
                                .clip(RoundedCornerShape(12.dp))
                                .background(MaterialTheme.colorScheme.surfaceVariant)
                                .clickable { countryMenuExpanded = true }
                                .padding(horizontal = 10.dp, vertical = 14.dp),
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            Text(text = selectedCountry.flag, fontSize = 20.sp)
                            Spacer(modifier = Modifier.width(4.dp))
                            Text(
                                text = selectedCountry.code,
                                style = MaterialTheme.typography.titleMedium,
                                fontWeight = FontWeight.Medium
                            )
                            Icon(
                                imageVector = Icons.Filled.ArrowDropDown,
                                contentDescription = null,
                                modifier = Modifier.size(16.dp),
                                tint = MaterialTheme.colorScheme.onSurfaceVariant
                            )
                        }
                        DropdownMenu(
                            expanded = countryMenuExpanded,
                            onDismissRequest = { countryMenuExpanded = false }
                        ) {
                            CountryCode.entries.forEach { country ->
                                DropdownMenuItem(
                                    text = { Text("${country.flag} ${country.code}") },
                                    onClick = {
                                        selectedCountry = country
                                        phoneNumber = ""
                                        countryMenuExpanded = false
                                    }
                                )
                            }
                        }
                    }

                    Spacer(modifier = Modifier.width(8.dp))

                    // Phone number field
                    OutlinedTextField(
                        value = phoneNumber,
                        onValueChange = { phoneNumber = it.filter { c -> c.isDigit() } },
                        placeholder = { Text(selectedCountry.placeholder) },
                        modifier = Modifier.weight(1f),
                        keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Phone),
                        singleLine = true,
                        shape = RoundedCornerShape(12.dp),
                        colors = OutlinedTextFieldDefaults.colors(
                            unfocusedContainerColor = MaterialTheme.colorScheme.surfaceVariant,
                            focusedContainerColor = MaterialTheme.colorScheme.surfaceVariant,
                            unfocusedBorderColor = Color.Transparent,
                            focusedBorderColor = Teal
                        )
                    )
                }

                Spacer(modifier = Modifier.height(16.dp))

                Button(
                    onClick = {
                        errorMessage = null
                        isLoading = true
                        val fullNumber = "${selectedCountry.code}${phoneNumber.filter { it.isDigit() }}"
                        scope.launch {
                            try {
                                authService.sendOTP(fullNumber)
                                showOTPField = true
                            } catch (e: Exception) {
                                errorMessage = e.message
                            }
                            isLoading = false
                        }
                    },
                    modifier = Modifier
                        .fillMaxWidth()
                        .height(56.dp),
                    enabled = phoneNumber.filter { it.isDigit() }.length >= selectedCountry.minDigits && !isLoading,
                    shape = RoundedCornerShape(14.dp),
                    colors = ButtonDefaults.buttonColors(containerColor = Teal)
                ) {
                    if (isLoading) {
                        CircularProgressIndicator(
                            modifier = Modifier.size(24.dp),
                            color = Color.White,
                            strokeWidth = 2.dp
                        )
                    } else {
                        Text("Send OTP", style = MaterialTheme.typography.titleMedium)
                    }
                }
            }
        }

        AnimatedVisibility(
            visible = showOTPField,
            enter = fadeIn() + slideInVertically(),
            exit = fadeOut() + slideOutVertically()
        ) {
            // OTP input section
            Column(horizontalAlignment = Alignment.CenterHorizontally) {
                Text(
                    text = "Enter the OTP sent to",
                    style = MaterialTheme.typography.titleMedium,
                    fontWeight = FontWeight.SemiBold
                )
                Spacer(modifier = Modifier.height(4.dp))
                Text(
                    text = "${selectedCountry.code} $phoneNumber",
                    style = MaterialTheme.typography.bodyMedium,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
                Spacer(modifier = Modifier.height(24.dp))

                OtpFieldView(
                    code = otpCode,
                    onCodeChange = { newCode ->
                        otpCode = newCode
                        if (newCode.length == 6) {
                            errorMessage = null
                            isLoading = true
                            scope.launch {
                                try {
                                    authService.verifyOTP(newCode)
                                    onLoginSuccess(authService.needsOnboarding.value)
                                } catch (e: Exception) {
                                    errorMessage = e.message
                                }
                                isLoading = false
                            }
                        }
                    }
                )
                Spacer(modifier = Modifier.height(16.dp))

                Button(
                    onClick = {
                        errorMessage = null
                        isLoading = true
                        scope.launch {
                            try {
                                authService.verifyOTP(otpCode)
                                onLoginSuccess(authService.needsOnboarding.value)
                            } catch (e: Exception) {
                                errorMessage = e.message
                            }
                            isLoading = false
                        }
                    },
                    modifier = Modifier
                        .fillMaxWidth()
                        .height(56.dp),
                    enabled = otpCode.length == 6 && !isLoading,
                    shape = RoundedCornerShape(14.dp),
                    colors = ButtonDefaults.buttonColors(containerColor = Teal)
                ) {
                    if (isLoading) {
                        CircularProgressIndicator(
                            modifier = Modifier.size(24.dp),
                            color = Color.White,
                            strokeWidth = 2.dp
                        )
                    } else {
                        Text("Verify", style = MaterialTheme.typography.titleMedium)
                    }
                }

                Spacer(modifier = Modifier.height(12.dp))

                TextButton(onClick = {
                    showOTPField = false
                    otpCode = ""
                    errorMessage = null
                }) {
                    Text("Change phone number", color = Teal)
                }
            }
        }

        // Error message
        errorMessage?.let { msg ->
            Spacer(modifier = Modifier.height(12.dp))
            Text(
                text = msg,
                color = MaterialTheme.colorScheme.error,
                style = MaterialTheme.typography.bodySmall,
                textAlign = TextAlign.Center
            )
        }

        Spacer(modifier = Modifier.weight(2f))
    }
}

@Composable
fun OtpFieldView(
    code: String,
    onCodeChange: (String) -> Unit
) {
    val focusRequester = remember { FocusRequester() }

    Box(
        contentAlignment = Alignment.Center
    ) {
        // Hidden text field for keyboard + OTP autofill
        BasicTextField(
            value = code,
            onValueChange = { newValue ->
                if (newValue.length <= 6 && newValue.all { it.isDigit() }) {
                    onCodeChange(newValue)
                }
            },
            keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.NumberPassword),
            modifier = Modifier
                .focusRequester(focusRequester)
                .size(1.dp)
        )

        // Visual OTP boxes
        Row(
            horizontalArrangement = Arrangement.spacedBy(8.dp),
            modifier = Modifier.clickable(
                indication = null,
                interactionSource = remember { MutableInteractionSource() }
            ) {
                focusRequester.requestFocus()
            }
        ) {
            repeat(6) { index ->
                val digit = if (index < code.length) code[index].toString() else ""
                val isActive = index == code.length

                Box(
                    modifier = Modifier
                        .size(width = 48.dp, height = 56.dp)
                        .clip(RoundedCornerShape(10.dp))
                        .background(MaterialTheme.colorScheme.surfaceVariant)
                        .then(
                            if (isActive) Modifier.border(2.dp, Teal, RoundedCornerShape(10.dp))
                            else Modifier
                        ),
                    contentAlignment = Alignment.Center
                ) {
                    Text(
                        text = digit,
                        style = MaterialTheme.typography.titleLarge,
                        fontWeight = FontWeight.SemiBold
                    )
                }
            }
        }
    }

    LaunchedEffect(Unit) {
        focusRequester.requestFocus()
    }
}
